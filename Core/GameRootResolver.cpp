#include "GameRootResolver.hpp"

#include <algorithm>
#include <cctype>
#include <sstream>
#include <system_error>

namespace kiripad {
namespace {

std::string lower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return s;
}

GameRootCandidate inspectDirectory(const std::filesystem::path& dir) {
    GameRootCandidate c;
    c.path = dir;
    std::error_code ec;
    for (std::filesystem::directory_iterator it(dir, std::filesystem::directory_options::skip_permission_denied, ec), end;
         !ec && it != end; ++it) {
        if (!it->is_regular_file(ec)) continue;
        const auto name = lower(it->path().filename().u8string());
        const auto ext = lower(it->path().extension().u8string());
        if (name == "data.xp3") c.hasDataXp3 = true;
        if (name == "startup.tjs") c.hasStartupTjs = true;
        if (name == "config.tjs") c.hasConfigTjs = true;
        if (ext == ".xp3") ++c.xp3Count;
        if (ext == ".exe") ++c.exeCount;
    }

    // Prefer the directory that contains the original archives/executable directly.
    if (c.hasDataXp3) c.score += 100;
    if (c.hasStartupTjs) c.score += 80;
    if (c.hasConfigTjs) c.score += 25;
    c.score += static_cast<int>(std::min<std::size_t>(c.xp3Count, 20) * 4);
    c.score += static_cast<int>(std::min<std::size_t>(c.exeCount, 5) * 3);
    return c;
}

} // namespace

GameRootResolution resolveGameRoot(const std::filesystem::path& selectedRoot,
                                   int maxDepth,
                                   std::size_t maxDirectories) {
    GameRootResolution r;
    r.selectedRoot = selectedRoot;
    std::error_code ec;
    if (!std::filesystem::is_directory(selectedRoot, ec)) {
        r.notes.emplace_back("選択パスをディレクトリとして開けませんでした。");
        return r;
    }

    r.candidates.push_back(inspectDirectory(selectedRoot));
    std::size_t inspected = 1;

    std::filesystem::recursive_directory_iterator it(
        selectedRoot, std::filesystem::directory_options::skip_permission_denied, ec);
    const std::filesystem::recursive_directory_iterator end;
    while (!ec && it != end && inspected < maxDirectories) {
        if (it.depth() >= maxDepth) {
            it.disable_recursion_pending();
        }
        if (it->is_directory(ec)) {
            const auto name = lower(it->path().filename().u8string());
            // Ignore common extracted/archive mirror directories as the game root.
            if (name == "outpath" || name.find("data.xp3~") != std::string::npos) {
                it.disable_recursion_pending();
                ++it;
                continue;
            }
            r.candidates.push_back(inspectDirectory(it->path()));
            ++inspected;
        }
        ++it;
    }

    std::stable_sort(r.candidates.begin(), r.candidates.end(), [](const auto& a, const auto& b) {
        if (a.score != b.score) return a.score > b.score;
        return a.path.u8string().size() < b.path.u8string().size();
    });

    if (!r.candidates.empty() && r.candidates.front().score >= 100) {
        r.gameRoot = r.candidates.front().path;
        r.found = true;
        if (r.gameRoot != selectedRoot) {
            r.notes.emplace_back("選択フォルダ直下から実ゲームルートを自動検出しました。");
        }
    } else {
        r.gameRoot = selectedRoot;
        r.notes.emplace_back("data.xp3を直接含むフォルダを特定できなかったため、選択フォルダを使用します。");
    }
    return r;
}

std::string formatGameRootResolution(const GameRootResolution& r) {
    std::ostringstream out;
    out << "ゲームルート解決\n";
    out << "Selected: " << r.selectedRoot.u8string() << "\n";
    out << "Resolved: " << r.gameRoot.u8string() << "\n";
    out << "Result: " << (r.found ? "自動検出" : "選択フォルダを使用") << "\n";
    if (!r.candidates.empty()) {
        const auto& c = r.candidates.front();
        out << "Score: " << c.score << " / XP3: " << c.xp3Count << " / EXE: " << c.exeCount << "\n";
    }
    for (const auto& note : r.notes) out << "- " << note << "\n";
    return out.str();
}

} // namespace kiripad
