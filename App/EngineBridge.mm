#import "EngineBridge.h"
#include "GameSignatureScanner.hpp"

@implementation EngineBridge

+ (NSString *)diagnoseGameFolderURL:(NSURL *)url {
    if (!url.isFileURL) return @"ファイルURLではありません。";
    const char *fsPath = url.fileSystemRepresentation;
    if (!fsPath) return @"パスをUTF-8へ変換できませんでした。";

    const auto result = kiripad::scanGameDirectory(std::filesystem::path(fsPath));
    const auto text = kiripad::formatScanResult(result, std::filesystem::path(fsPath));
    return [[NSString alloc] initWithBytes:text.data()
                                   length:text.size()
                                 encoding:NSUTF8StringEncoding] ?: @"診断結果の表示に失敗しました。";
}

+ (BOOL)isRuntimeLinked {
    return NO;
}

+ (NSString *)runtimeStatusText {
    return @"Phase 1ではランタイムはまだ未接続です。まずゲーム構成の診断とiOSネイティブ起動基盤を固めます。";
}

@end
