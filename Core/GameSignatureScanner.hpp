#pragma once

#include <cstddef>
#include <filesystem>
#include <string>
#include <vector>

namespace kiripad {

struct ScanResult {
    bool rootExists = false;
    bool hasDataXp3 = false;
    bool hasStartupTjs = false;
    bool hasPatchTjs = false;
    bool hasConfigTjs = false;
    bool likelyKirikiri = false;

    std::size_t xp3Count = 0;
    std::size_t tjsCount = 0;
    std::size_t ksCount = 0;
    std::size_t dllCount = 0;
    std::size_t tpmCount = 0;
    std::size_t exeCount = 0;
    std::size_t videoCount = 0;
    std::size_t audioCount = 0;
    std::size_t scannedEntries = 0;

    std::vector<std::string> nativePluginFiles;
    std::vector<std::string> interestingFiles;
    std::vector<std::string> warnings;
};

ScanResult scanGameDirectory(const std::filesystem::path& root,
                             std::size_t maxEntries = 6000,
                             int maxDepth = 4);
std::string formatScanResult(const ScanResult& result, const std::filesystem::path& root);

} // namespace kiripad
