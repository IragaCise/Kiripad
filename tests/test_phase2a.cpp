#include "GameRootResolver.hpp"
#include "StartupProbe.hpp"

#include <cassert>
#include <filesystem>
#include <fstream>
#include <iostream>

int main() {
    auto outer = std::filesystem::temp_directory_path() / "kiripad_phase2a_test";
    auto game = outer / u8"サノバウィッチ";
    std::filesystem::remove_all(outer);
    std::filesystem::create_directories(game / "plugin");
    std::filesystem::create_directories(game / "plain");
    std::ofstream(game / "data.xp3") << "dummy";
    std::ofstream(game / "config.tjs") << "dummy";
    std::ofstream(game / "game.exe") << "dummy";
    std::ofstream(game / "plugin" / "yuzuex.dll") << "dummy";
    std::ofstream(game / "plugin" / "windowEx.dll") << "dummy";
    std::ofstream(game / "plain" / "boot.tjs") << "Plugins.link(\"windowEx.dll\"); Plugins.link(\"yuzuex.dll\");";

    auto resolved = kiripad::resolveGameRoot(outer);
    assert(resolved.found);
    assert(resolved.gameRoot == game);

    auto probe = kiripad::probeStartupRequirements(game);
    assert(probe.plugins.size() == 2);
    assert(probe.plaintextScriptsRead >= 2);
    bool sawYuzu = false;
    bool sawWindow = false;
    for (const auto& p : probe.plugins) {
        if (p.fileName == "yuzuex.dll") {
            sawYuzu = true;
            assert(p.priority == kiripad::PluginPriority::GameSpecific);
            assert(p.referencedByPlaintextScript);
        }
        if (p.fileName == "windowEx.dll") {
            sawWindow = true;
            assert(p.priority == kiripad::PluginPriority::PortableCandidate);
            assert(p.referencedByPlaintextScript);
        }
    }
    assert(sawYuzu && sawWindow);

    std::filesystem::remove_all(outer);
    std::cout << "phase2a tests passed\n";
    return 0;
}
