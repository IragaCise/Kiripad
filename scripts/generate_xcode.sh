#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build-ios"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must be run on macOS with Xcode and CMake installed." >&2
  exit 1
fi

cmake -S "$ROOT" -B "$BUILD" -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0

echo
printf 'Generated: %s\n' "$BUILD/KiriPadPhase2A.xcodeproj"
echo "Open it in Xcode, set your Development Team for the KiriPad target, select your iPad, and Run."
open "$BUILD/KiriPadPhase2A.xcodeproj"
