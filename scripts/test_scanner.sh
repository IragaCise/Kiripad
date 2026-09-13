#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/.build-tools"
mkdir -p "$OUT"

c++ -std=c++17 -Wall -Wextra \
  -I"$ROOT/Core" \
  "$ROOT/Core/GameSignatureScanner.cpp" \
  "$ROOT/tests/test_scanner.cpp" \
  -o "$OUT/test_scanner"
"$OUT/test_scanner"

c++ -std=c++17 -Wall -Wextra \
  -I"$ROOT/Core" \
  "$ROOT/Core/GameRootResolver.cpp" \
  "$ROOT/Core/StartupProbe.cpp" \
  "$ROOT/tests/test_phase2a.cpp" \
  -o "$OUT/test_phase2a"
"$OUT/test_phase2a"

c++ -std=c++17 -Wall -Wextra \
  -I"$ROOT/Core" \
  "$ROOT/Core/GameSignatureScanner.cpp" \
  "$ROOT/tools/inspect_game.cpp" \
  -o "$OUT/kiripad-inspect"
echo "Built: $OUT/kiripad-inspect"
