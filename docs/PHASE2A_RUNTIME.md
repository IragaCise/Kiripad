# Phase 2A Runtime architecture

The runtime-linked build uses the public KrKr2-Next `engine_api` ABI. The engine is fetched and built only in GitHub Actions; it is not vendored in this source archive.

Flow:

1. Resolve selected folder to likely game root.
2. Static preflight of already-plain TJS/KS and native plug-in files.
3. `engine_create` with app-owned writable/cache paths.
4. `engine_open_game_async(gameRoot, nullptr)`.
5. 60-ish Hz `engine_tick` on a serial engine queue.
6. Drain startup logs and show them in the UI.
7. If RGBA frame readback is available, show it in `EngineRenderView`.
8. Map one-finger touches to engine pointer events.

The first useful failure is expected to become the input for Phase 2B compatibility work.
