# Roadmap

## Phase 1 — Host & Diagnostics（このZIP）

- [x] iPad用ネイティブホスト
- [x] フォルダピッカー
- [x] security-scoped resource access
- [x] 吉里吉里構成診断
- [x] Windowsネイティブプラグイン候補の検出
- [x] PC用診断CLIと単体テスト
- [x] krkrsdl2 iOSビルド補助

## Phase 2 — First Frame

目標: サノバウィッチのタイトル画面まで。

- [ ] 採用エンジンを確定（第一実装候補: KrKr2-Next。互換実装の参照: Kirikiroid2。iOSビルド基準: krkrsdl2）
- [ ] engine_create / engine_run等の安定したC APIを定義
- [ ] iOS sandboxパスのストレージ層
- [ ] TJS初期化
- [ ] XP3読み込み（標準形式のみ）
- [ ] SDL/ANGLE/Metal描画接続
- [ ] タッチ入力
- [ ] ログ収集画面

## Phase 3 — Playable Sanoba Witch

- [ ] フォント
- [ ] BGM/SE/Voice
- [ ] セーブ/ロード
- [ ] バックログ/選択肢
- [ ] 動画
- [ ] 作品固有プラグイン互換層
- [ ] 1ルートの通しテスト

## Phase 4 — Milk Factory / Spy School

- [ ] Phase 3との差分ログを採取
- [ ] KiriKiri Z固有API
- [ ] Live2D/特殊描画の有無を確認
- [ ] 動画・音声差分
- [ ] ネイティブプラグイン代替実装
- [ ] タイトル → 本編 → セーブまで

## 設計原則

- 作品別ハックは `Compatibility/<vendor>/<title>` に隔離する
- エンジン本体へ直書きしない
- DRM/ライセンス回避を互換レイヤーへ混ぜない
- 不明なWindows APIはログを残して最小実装する
- 最初から完全互換を目指さず、失敗箇所を観測可能にする
