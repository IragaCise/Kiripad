#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/vendor"
mkdir -p "$VENDOR"

clone_if_missing() {
  local url="$1" dir="$2" recursive="${3:-no}"
  if [[ -d "$dir/.git" ]]; then
    echo "Already present: $dir"
    return
  fi
  if [[ "$recursive" == "yes" ]]; then
    git clone --recursive "$url" "$dir"
  else
    git clone "$url" "$dir"
  fi
}

clone_if_missing https://github.com/krkrsdl2/krkrsdl2.git "$VENDOR/krkrsdl2" yes
clone_if_missing https://github.com/zeas2/Kirikiroid2.git "$VENDOR/Kirikiroid2" no
clone_if_missing https://github.com/reAAAq/KrKr2-Next.git "$VENDOR/KrKr2-Next" yes

echo "Reference engines fetched under $VENDOR"
