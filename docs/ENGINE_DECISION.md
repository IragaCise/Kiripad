# Engine decision for Phase 2

## 1. KrKr2-Next — 第一実装候補

理由:

- iOSのビルド/実行経路が既に通っている
- `engine_create` / `engine_tick` / `engine_destroy` のようなC APIブリッジが既にある
- Flutter + ANGLE + Metal系の構成で、iPad向けUIとエンジンを分離しやすい
- 2026年時点で活発に開発されている

弱点:

- iOSのOpenGL/描画部分はまだ最適化・修正中
- Kirikiri Z系の互換性はまだ拡張中
- GPL-3.0なので派生物の配布条件に注意

## 2. Kirikiroid2 — 互換性の実装参照

理由:

- KiriKiri2/Zの市販作品互換で長い実績がある
- 動画・追加プラグイン等の実装が参考になる
- 過去の公式リリースにはiOS対応実績がある

弱点:

- 現在公開されているトップレベル構成はAndroid中心
- iOS向け公開ビルド手順・ソース構成が古い

## 3. krkrsdl2 — iOSネイティブ基準

理由:

- 現在のCMakeにiOSターゲットとコード署名設定が残っている
- iPhone/iPad向けターゲット設定がある
- iOS上で吉里吉里コアをネイティブビルドする基準として使いやすい

弱点:

- 上流が未変更の商用ゲーム実行をサポート対象外としている

## Phase 2方針

KiriPadホストにKrKr2-NextのC APIを接続する試作を最初に行う。
サノバウィッチで不足APIやプラグインをログ化し、必要な互換実装をKirikiroid2から設計上参考にする。
krkrsdl2はエンジンそのもののiOSビルドが壊れていないかを切り分ける比較対象として維持する。
