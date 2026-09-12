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

APP_PATH="$DERIVED_DATA/Build/Products/Release-iphoneos/KiriPad.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app bundle not found: $APP_PATH" >&2
  find "$DERIVED_DATA/Build/Products" -maxdepth 3 -type d -name '*.app' -print || true
  exit 1
fi

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
