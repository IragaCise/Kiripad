# Phase 1.2 CI packaging fix

GitHub Actions / Xcode 26 may place `KiriPad.app` directly under
`build-ios-ci/Release-iphoneos/` even when `-derivedDataPath` is supplied.
The unsigned IPA packaging script now checks both common output locations and
falls back to locating `KiriPad.app` under the build/derived-data trees.

The workflow also invokes shell scripts through `bash` so browser uploads do
not depend on preserved executable permission bits.
