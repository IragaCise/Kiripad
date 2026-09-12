#include "GameSignatureScanner.hpp"
#include <filesystem>
#include <iostream>

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "Usage: kiripad-inspect <game-directory>\n";
        return 2;
    }
    const std::filesystem::path root(argv[1]);
    auto result = kiripad::scanGameDirectory(root);
    std::cout << kiripad::formatScanResult(result, root);
    return result.rootExists ? 0 : 1;
}
