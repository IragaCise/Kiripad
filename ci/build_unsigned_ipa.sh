#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build-ios-ci"
DERIVED_DATA="$ROOT/.derived-data"
ARTIFACT_DIR="$ROOT/artifacts"
BUNDLE_ID="${KIRIPAD_BUNDLE_ID:-dev.kiripad.phase1}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: iOS device build requires macOS/Xcode." >&2
  exit 1
fi

rm -rf "$BUILD_DIR" "$DERIVED_DATA" "$ARTIFACT_DIR"
mkdir -p "$ARTIFACT_DIR"

cmake -S "$ROOT" -B "$BUILD_DIR" -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
  -DKIRIPAD_BUNDLE_ID="$BUNDLE_ID" \
  -DKIRIPAD_CODE_SIGNING=OFF

xcodebuild \
  -project "$BUILD_DIR/KiriPadPhase1.xcodeproj" \
  -scheme KiriPad \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH=""
for candidate in \
  "$DERIVED_DATA/Build/Products/Release-iphoneos/KiriPad.app" \
  "$BUILD_DIR/Release-iphoneos/KiriPad.app"; do
  if [[ -d "$candidate" ]]; then
    APP_PATH="$candidate"
    break
  fi
done

if [[ -z "$APP_PATH" ]]; then
  APP_PATH=$(find "$DERIVED_DATA" "$BUILD_DIR" -type d -name 'KiriPad.app' -print -quit 2>/dev/null || true)
fi

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "error: KiriPad.app was not found after a successful Xcode build." >&2
  echo "Searched under:" >&2
  echo "  $DERIVED_DATA" >&2
  echo "  $BUILD_DIR" >&2
  find "$DERIVED_DATA" "$BUILD_DIR" -maxdepth 5 -type d -name '*.app' -print 2>/dev/null || true
  exit 1
fi

printf 'Found app bundle:\n  %s\n' "$APP_PATH"

cp -R "$APP_PATH" "$ARTIFACT_DIR/KiriPad.app"
mkdir -p "$ARTIFACT_DIR/Payload"
cp -R "$APP_PATH" "$ARTIFACT_DIR/Payload/KiriPad.app"
(
  cd "$ARTIFACT_DIR"
  /usr/bin/zip -qry KiriPad-unsigned.ipa Payload
)
rm -rf "$ARTIFACT_DIR/Payload"

printf '\nBuilt unsigned IPA:\n  %s\n' "$ARTIFACT_DIR/KiriPad-unsigned.ipa"
printf 'Bundle ID:\n  %s\n' "$BUNDLE_ID"
printf '\nThis IPA is intentionally unsigned and must be signed before installation on a physical iPad.\n'
