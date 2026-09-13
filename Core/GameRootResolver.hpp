#pragma once

#include <filesystem>
#include <string>
#include <vector>

namespace kiripad {

struct GameRootCandidate {
    std::filesystem::path path;
    int score = 0;
    bool hasDataXp3 = false;
    bool hasStartupTjs = false;
    bool hasConfigTjs = false;
    std::size_t xp3Count = 0;
    std::size_t exeCount = 0;
};

struct GameRootResolution {
    std::filesystem::path selectedRoot;
    std::filesystem::path gameRoot;
    std::vector<GameRootCandidate> candidates;
    std::vector<std::string> notes;
    bool found = false;
};

GameRootResolution resolveGameRoot(const std::filesystem::path& selectedRoot,
                                   int maxDepth = 2,
                                   std::size_t maxDirectories = 256);
std::string formatGameRootResolution(const GameRootResolution& r);

} // namespace kiripad
