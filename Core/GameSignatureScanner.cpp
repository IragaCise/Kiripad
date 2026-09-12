#include "GameSignatureScanner.hpp"

#include <algorithm>
#include <cctype>
#include <sstream>
#include <system_error>
#include <unordered_set>

namespace kiripad {
namespace {

std::string lower(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return value;
}

bool isOneOf(const std::string& ext, const std::unordered_set<std::string>& set) {
    return set.find(ext) != set.end();
}

void remember(std::vector<std::string>& out, const std::filesystem::path& root,
              const std::filesystem::path& path, std::size_t limit = 32) {
    if (out.size() >= limit) return;
    std::error_code ec;
    auto rel = std::filesystem::relative(path, root, ec);
    out.push_back(ec ? path.filename().u8string() : rel.u8string());
}

} // namespace

ScanResult scanGameDirectory(const std::filesystem::path& root,
                             std::size_t maxEntries,
                             int maxDepth) {
    ScanResult r;
    std::error_code ec;
    r.rootExists = std::filesystem::exists(root, ec) && std::filesystem::is_directory(root, ec);
    if (!r.rootExists) {
        r.warnings.emplace_back("選択されたパスをディレクトリとして開けませんでした。");
        return r;
    }

    const std::unordered_set<std::string> videoExt = {
        ".mp4", ".m4v", ".mov", ".wmv", ".avi", ".webm", ".mpg", ".mpeg"
    };
    const std::unordered_set<std::string> audioExt = {
        ".ogg", ".wav", ".mp3", ".m4a", ".opus", ".flac"
    };

    std::filesystem::recursive_directory_iterator it(
        root,
        std::filesystem::directory_options::skip_permission_denied,
        ec
    );
    const std::filesystem::recursive_directory_iterator end;

    while (!ec && it != end && r.scannedEntries < maxEntries) {
        if (it.depth() > maxDepth) {
            it.disable_recursion_pending();
            ++it;
            continue;
        }

        const auto path = it->path();
        ++r.scannedEntries;

        if (it->is_regular_file(ec)) {
            const std::string filename = lower(path.filename().u8string());
            const std::string ext = lower(path.extension().u8string());

            if (filename == "data.xp3") r.hasDataXp3 = true;
            if (filename == "startup.tjs") r.hasStartupTjs = true;
            if (filename == "patch.tjs") r.hasPatchTjs = true;
            if (filename == "config.tjs") r.hasConfigTjs = true;

            if (ext == ".xp3") { ++r.xp3Count; remember(r.interestingFiles, root, path); }
            else if (ext == ".tjs") { ++r.tjsCount; remember(r.interestingFiles, root, path); }
            else if (ext == ".ks") { ++r.ksCount; }
            else if (ext == ".dll") { ++r.dllCount; remember(r.nativePluginFiles, root, path); }
            else if (ext == ".tpm") { ++r.tpmCount; remember(r.nativePluginFiles, root, path); }
            else if (ext == ".exe") { ++r.exeCount; remember(r.interestingFiles, root, path); }
            else if (isOneOf(ext, videoExt)) { ++r.videoCount; }
            else if (isOneOf(ext, audioExt)) { ++r.audioCount; }
        }
        ++it;
    }

    if (r.scannedEntries >= maxEntries) {
        r.warnings.emplace_back("ファイル数上限に達したため、診断は途中で打ち切られました。");
    }

    r.likelyKirikiri = r.hasStartupTjs || r.hasDataXp3 || r.xp3Count > 0 || r.tjsCount >= 3;

    if (r.dllCount + r.tpmCount > 0) {
        r.warnings.emplace_back("Windows/ネイティブ系プラグイン候補があります。iPadでは互換実装が必要になる可能性があります。");
    }
    if (r.videoCount > 0) {
        r.warnings.emplace_back("動画ファイルがあります。コーデックと再生APIの互換性確認が必要です。");
    }
    if (!r.hasDataXp3 && r.xp3Count == 0 && !r.hasStartupTjs) {
        r.warnings.emplace_back("典型的なdata.xp3/startup.tjsを検出できませんでした。");
    }

    return r;
}

std::string formatScanResult(const ScanResult& r, const std::filesystem::path& root) {
    std::ostringstream out;
    out << "KiriPad Phase 1 診断\n";
    out << "Path: " << root.u8string() << "\n\n";
    out << "Kirikiri系の可能性: " << (r.likelyKirikiri ? "高い" : "未確認") << "\n";
    out << "data.xp3: " << (r.hasDataXp3 ? "あり" : "なし") << "\n";
    out << "startup.tjs: " << (r.hasStartupTjs ? "あり" : "なし") << "\n";
    out << "patch.tjs: " << (r.hasPatchTjs ? "あり" : "なし") << "\n";
    out << "config.tjs: " << (r.hasConfigTjs ? "あり" : "なし") << "\n\n";
    out << "XP3: " << r.xp3Count << "\n";
    out << "TJS: " << r.tjsCount << "\n";
    out << "KAG/KS: " << r.ksCount << "\n";
    out << "DLL: " << r.dllCount << "\n";
    out << "TPM: " << r.tpmCount << "\n";
    out << "EXE: " << r.exeCount << "\n";
    out << "Video: " << r.videoCount << "\n";
    out << "Audio: " << r.audioCount << "\n";
    out << "Scanned: " << r.scannedEntries << " entries\n";

    if (!r.nativePluginFiles.empty()) {
        out << "\nネイティブプラグイン候補:\n";
        for (const auto& f : r.nativePluginFiles) out << "  - " << f << "\n";
    }
    if (!r.interestingFiles.empty()) {
        out << "\n主要ファイル:\n";
        for (const auto& f : r.interestingFiles) out << "  - " << f << "\n";
    }
    if (!r.warnings.empty()) {
        out << "\n注意:\n";
        for (const auto& w : r.warnings) out << "  - " << w << "\n";
    }
    return out.str();
}

} // namespace kiripad
