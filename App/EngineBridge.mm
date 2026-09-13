#import "EngineBridge.h"
#import "EngineRuntimeHost.h"
#include "GameRootResolver.hpp"
#include "GameSignatureScanner.hpp"
#include "StartupProbe.hpp"

namespace {
std::filesystem::path pathForURL(NSURL *url) {
    const char *fsPath = url.fileSystemRepresentation;
    return fsPath ? std::filesystem::path(fsPath) : std::filesystem::path();
}

NSString *stringFromStd(const std::string& value) {
    return [[NSString alloc] initWithBytes:value.data() length:value.size() encoding:NSUTF8StringEncoding] ?: @"(UTF-8変換失敗)";
}
}

@implementation EngineBridge

+ (NSURL *)resolvedGameRootURLForSelectedURL:(NSURL *)url {
    if (!url.isFileURL) return nil;
    const auto selected = pathForURL(url);
    if (selected.empty()) return nil;
    const auto resolution = kiripad::resolveGameRoot(selected);
    const auto& root = resolution.gameRoot.empty() ? selected : resolution.gameRoot;
    return [NSURL fileURLWithPath:stringFromStd(root.u8string()) isDirectory:YES];
}

+ (NSString *)diagnoseGameFolderURL:(NSURL *)url {
    if (!url.isFileURL) return @"ファイルURLではありません。";
    const auto selected = pathForURL(url);
    if (selected.empty()) return @"パスをUTF-8へ変換できませんでした。";

    const auto resolution = kiripad::resolveGameRoot(selected);
    const auto& root = resolution.gameRoot.empty() ? selected : resolution.gameRoot;
    const auto scan = kiripad::scanGameDirectory(root);

    std::string text = "KiriPad Phase 2A 診断\n\n";
    text += kiripad::formatGameRootResolution(resolution);
    text += "\n";
    text += kiripad::formatScanResult(scan, root);
    return stringFromStd(text);
}

+ (NSString *)startupProbeForGameFolderURL:(NSURL *)url {
    if (!url.isFileURL) return @"ファイルURLではありません。";
    const auto selected = pathForURL(url);
    const auto resolution = kiripad::resolveGameRoot(selected);
    const auto& root = resolution.gameRoot.empty() ? selected : resolution.gameRoot;
    const auto probe = kiripad::probeStartupRequirements(root);
    return stringFromStd(kiripad::formatStartupProbe(probe));
}

+ (BOOL)isRuntimeLinked {
    return [EngineRuntimeHost isEngineLinked];
}

+ (NSString *)runtimeStatusText {
    if ([self isRuntimeLinked]) {
        return [NSString stringWithFormat:@"ランタイム: %@\nゲームを選択後、「ランタイム起動」でstartup.tjsまで進み、起動ログを収集します。", [EngineRuntimeHost backendDescription]];
    }
    return @"このIPAは軽量プローブ版です。実ランタイムを試すにはGitHub Actionsの「Build KiriPad Phase 2A Runtime」を実行してください。";
}

@end
