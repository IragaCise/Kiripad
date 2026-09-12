#include "GameSignatureScanner.hpp"
#include <cassert>
#include <filesystem>
#include <fstream>
#include <iostream>

int main() {
    auto root = std::filesystem::temp_directory_path() / "kiripad_scanner_test";
    std::filesystem::remove_all(root);
    std::filesystem::create_directories(root / "plugin");
    std::ofstream(root / "data.xp3") << "dummy";
    std::ofstream(root / "startup.tjs") << "dummy";
    std::ofstream(root / "plugin" / "sample.dll") << "dummy";
    std::ofstream(root / "movie.mp4") << "dummy";

    auto r = kiripad::scanGameDirectory(root);
    assert(r.rootExists);
    assert(r.hasDataXp3);
    assert(r.hasStartupTjs);
    assert(r.likelyKirikiri);
    assert(r.xp3Count == 1);
    assert(r.tjsCount == 1);
    assert(r.dllCount == 1);
    assert(r.videoCount == 1);
    assert(!r.warnings.empty());

    std::filesystem::remove_all(root);
    std::cout << "scanner tests passed\n";
    return 0;
}
