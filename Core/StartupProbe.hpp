#pragma once

#include <filesystem>
#include <string>
#include <vector>

namespace kiripad {

enum class PluginPriority {
    PortableCandidate,
    WindowsShim,
    MediaOrRenderer,
    GameSpecific,
    Unknown
};

struct PluginProbeEntry {
    std::string fileName;
    std::string relativePath;
    PluginPriority priority = PluginPriority::Unknown;
    std::string note;
    bool referencedByPlaintextScript = false;
    std::vector<std::string> referenceFiles;
};

struct StartupProbeResult {
    std::filesystem::path root;
    std::vector<PluginProbeEntry> plugins;
    std::vector<std::string> scriptDllReferences;
    std::vector<std::string> warnings;
    std::size_t plaintextScriptsRead = 0;
    std::size_t bytesRead = 0;
};

StartupProbeResult probeStartupRequirements(const std::filesystem::path& root,
                                            std::size_t maxFiles = 12000,
                                            std::size_t maxBytesPerFile = 2 * 1024 * 1024);
std::string formatStartupProbe(const StartupProbeResult& r);
const char* pluginPriorityLabel(PluginPriority priority);

} // namespace kiripad
