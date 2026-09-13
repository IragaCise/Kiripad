#include "StartupProbe.hpp"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <regex>
#include <set>
#include <sstream>
#include <system_error>
#include <unordered_map>

namespace kiripad {
namespace {

std::string lower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return s;
}

std::pair<PluginPriority, std::string> classify(const std::string& baseLower) {
    static const std::set<std::string> portable = {
        "kagparserex.dll", "layerexdraw.dll", "layerexsave.dll", "varfile.dll",
        "getsample.dll", "windowex.dll", "win32dialog.dll", "wuvorbis.dll",
        "wuopus.dll", "extrans.dll", "multiimage.dll", "textrender.dll",
        "psbfile.dll", "k2compat.dll"
    };
    static const std::set<std::string> windowsShim = {
        "shellexecute.dll", "win32ole.dll", "menu.dll"
    };
    static const std::set<std::string> media = {
        "drawdeviced3d.dll", "drawdeviced3dz.dll", "motionplayer.dll",
        "alphamovie.dll", "krmovie.dll"
    };
    if (baseLower == "yuzuex.dll") {
        return {PluginPriority::GameSpecific, "ゆずソフト固有拡張候補。起動ログで最優先確認。"};
    }
    if (portable.count(baseLower)) {
        return {PluginPriority::PortableCandidate, "他の吉里吉里互換ランタイムで類似互換実装がある可能性が高い候補。"};
    }
    if (windowsShim.count(baseLower)) {
        return {PluginPriority::WindowsShim, "Windows API依存をiOS側の機能へ置換する候補。"};
    }
    if (media.count(baseLower)) {
        return {PluginPriority::MediaOrRenderer, "描画・動画系。iOS/Metal/AVFoundation側の置換が必要になる可能性。"};
    }
    return {PluginPriority::Unknown, "未分類。実際にロード要求された時点で挙動を確認。"};
}

std::string relString(const std::filesystem::path& root, const std::filesystem::path& path) {
    std::error_code ec;
    auto rel = std::filesystem::relative(path, root, ec);
    return ec ? path.filename().u8string() : rel.u8string();
}

} // namespace

const char* pluginPriorityLabel(PluginPriority p) {
    switch (p) {
        case PluginPriority::PortableCandidate: return "互換候補";
        case PluginPriority::WindowsShim: return "Windows置換";
        case PluginPriority::MediaOrRenderer: return "描画/動画";
        case PluginPriority::GameSpecific: return "作品固有";
        default: return "未分類";
    }
}

StartupProbeResult probeStartupRequirements(const std::filesystem::path& root,
                                            std::size_t maxFiles,
                                            std::size_t maxBytesPerFile) {
    StartupProbeResult r;
    r.root = root;
    std::error_code ec;
    if (!std::filesystem::is_directory(root, ec)) {
        r.warnings.emplace_back("ゲームルートを開けませんでした。");
        return r;
    }

    std::unordered_map<std::string, std::size_t> pluginByLowerName;
    std::filesystem::recursive_directory_iterator it(
        root, std::filesystem::directory_options::skip_permission_denied, ec);
    const std::filesystem::recursive_directory_iterator end;
    std::size_t visited = 0;

    while (!ec && it != end && visited < maxFiles) {
        ++visited;
        if (it.depth() > 7) {
            it.disable_recursion_pending();
            ++it;
            continue;
        }
        if (it->is_regular_file(ec)) {
            const auto path = it->path();
            const auto ext = lower(path.extension().u8string());
            if (ext == ".dll" || ext == ".tpm") {
                PluginProbeEntry e;
                e.fileName = path.filename().u8string();
                e.relativePath = relString(root, path);
                auto [priority, note] = classify(lower(e.fileName));
                e.priority = priority;
                e.note = std::move(note);
                pluginByLowerName[lower(e.fileName)] = r.plugins.size();
                r.plugins.push_back(std::move(e));
            }
        }
        ++it;
    }

    // Read only already-plain TJS/KS files. XP3 archives are not unpacked or altered.
    const std::regex dllRegex(R"(([A-Za-z0-9_+.-]+\.(?:dll|tpm)))", std::regex::icase);
    std::set<std::string> uniqueRefs;
    ec.clear();
    std::filesystem::recursive_directory_iterator sit(
        root, std::filesystem::directory_options::skip_permission_denied, ec);
    visited = 0;
    while (!ec && sit != end && visited < maxFiles) {
        ++visited;
        if (sit.depth() > 9) {
            sit.disable_recursion_pending();
            ++sit;
            continue;
        }
        if (sit->is_regular_file(ec)) {
            const auto path = sit->path();
            const auto ext = lower(path.extension().u8string());
            if (ext == ".tjs" || ext == ".ks") {
                std::ifstream in(path, std::ios::binary);
                if (in) {
                    std::string data;
                    data.resize(maxBytesPerFile);
                    in.read(data.data(), static_cast<std::streamsize>(data.size()));
                    data.resize(static_cast<std::size_t>(in.gcount()));
                    ++r.plaintextScriptsRead;
                    r.bytesRead += data.size();
                    const std::string sourceRel = relString(root, path);
                    for (std::sregex_iterator m(data.begin(), data.end(), dllRegex), mend; m != mend; ++m) {
                        const std::string ref = (*m)[1].str();
                        const std::string key = lower(std::filesystem::path(ref).filename().u8string());
                        uniqueRefs.insert(ref);
                        auto found = pluginByLowerName.find(key);
                        if (found != pluginByLowerName.end()) {
                            auto& e = r.plugins[found->second];
                            e.referencedByPlaintextScript = true;
                            if (e.referenceFiles.size() < 8 &&
                                std::find(e.referenceFiles.begin(), e.referenceFiles.end(), sourceRel) == e.referenceFiles.end()) {
                                e.referenceFiles.push_back(sourceRel);
                            }
                        }
                    }
                }
            }
        }
        ++sit;
    }
    r.scriptDllReferences.assign(uniqueRefs.begin(), uniqueRefs.end());

    std::stable_sort(r.plugins.begin(), r.plugins.end(), [](const auto& a, const auto& b) {
        if (a.referencedByPlaintextScript != b.referencedByPlaintextScript)
            return a.referencedByPlaintextScript > b.referencedByPlaintextScript;
        if (a.priority != b.priority)
            return static_cast<int>(a.priority) < static_cast<int>(b.priority);
        return lower(a.fileName) < lower(b.fileName);
    });

    if (r.plugins.empty()) r.warnings.emplace_back("DLL/TPMプラグインは検出されませんでした。");
    if (r.plaintextScriptsRead == 0) {
        r.warnings.emplace_back("平文TJS/KSが見つからないため、実際のプラグイン要求順はランタイムログで確認します。");
    }
    return r;
}

std::string formatStartupProbe(const StartupProbeResult& r) {
    std::ostringstream out;
    out << "\nPhase 2A 起動前プローブ\n";
    out << "Root: " << r.root.u8string() << "\n";
    out << "Plugin files: " << r.plugins.size() << "\n";
    out << "Plain TJS/KS read: " << r.plaintextScriptsRead << "\n";
    out << "Plaintext DLL refs: " << r.scriptDllReferences.size() << "\n\n";
    if (!r.plugins.empty()) {
        out << "プラグイン優先度（これは互換性保証ではありません）:\n";
        for (const auto& p : r.plugins) {
            out << "  [" << pluginPriorityLabel(p.priority) << "] " << p.fileName;
            if (p.referencedByPlaintextScript) out << "  <script参照あり>";
            out << "\n      " << p.note << "\n";
            for (const auto& f : p.referenceFiles) out << "      from: " << f << "\n";
        }
    }
    if (!r.scriptDllReferences.empty()) {
        out << "\n平文スクリプト内のDLL/TPM参照:\n";
        for (const auto& ref : r.scriptDllReferences) out << "  - " << ref << "\n";
    }
    if (!r.warnings.empty()) {
        out << "\n注意:\n";
        for (const auto& w : r.warnings) out << "  - " << w << "\n";
    }
    return out.str();
}

} // namespace kiripad
