#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/vendor"
SRC="$VENDOR/krkrsdl2"
BUILD="$ROOT/build-krkrsdl2-ios"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Run this on macOS with Xcode, git and CMake installed." >&2
  exit 1
fi

mkdir -p "$VENDOR"
if [[ ! -d "$SRC/.git" ]]; then
  git clone --recursive https://github.com/krkrsdl2/krkrsdl2.git "$SRC"
else
  git -C "$SRC" submodule update --init --recursive
fi

cmake -S "$SRC" -B "$BUILD" -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0

echo
printf 'Generated Kirikiri SDL2 iOS project: %s\n' "$BUILD/krkrsdl2.xcodeproj"
echo "Open in Xcode and configure Signing & Capabilities."
open "$BUILD/krkrsdl2.xcodeproj"
