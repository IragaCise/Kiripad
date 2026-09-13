# KiriPad Phase 2A

KiriPad Phase 2A は、所有している吉里吉里系ゲームを iPad 上で検証するための実験プロジェクトです。
今回の目標は「サノバウィッチ」を最終的に起動できる互換ランタイムを作ることですが、Phase 2A ではまず **どこで起動が止まるかを正確なログとして得る** ことを優先します。

## Phase 2Aで追加したもの

- 選択フォルダが `Documents` のような親フォルダでも、直下/浅い階層から `data.xp3` を持つゲームルートを自動検出
- DLL/TPM のインベントリと優先度表示
- 既に平文で存在する TJS/KS 内の DLL/TPM 参照を読み取り（XP3の展開・復号はしません）
- KrKr2-Next の public `engine_api` に接続する実験ランタイムホスト
- startup ログの iPad 画面表示
- RGBA フレームが取得できる場合の画面表示
- iPad タッチを pointer down/move/up としてランタイムへ送信
- GitHub Actions で「軽量プローブIPA」と「実ランタイムIPA」を別々にビルド

## 重要: 2つのWorkflow

### 1. Build KiriPad iOS

軽量版です。KrKr2-Next をリンクしません。

- ビルドが速い
- ゲームルート解決
- ファイル診断
- 起動前プローブ
- ランタイム起動ボタンは無効

### 2. Build KiriPad Phase 2A Runtime

実験ランタイム版です。GitHub Actions が KrKr2-Next のソースを取得し、iOS向け静的ライブラリをビルドして KiriPad にリンクします。

初回は vcpkg / ANGLE / FFmpeg 等の依存関係ビルドがあるため、かなり時間がかかる可能性があります。

Artifacts:

- `KiriPad-Phase2A-runtime-unsigned-ipa`
- `KiriPad-Phase2A-runtime-source-info`

後者には、ビルドに使った KrKr2-Next の正確な Git commit とライセンスを保存します。

## 実ランタイム版の手順

1. このフォルダの中身を GitHub リポジトリへアップロード/上書きします。
2. GitHub → Actions → `Build KiriPad Phase 2A Runtime` を開きます。
3. `Run workflow` を押します。`engine_ref` は最初は `main` のままで構いません。
4. 成功後、Artifacts の `KiriPad-Phase2A-runtime-unsigned-ipa` をダウンロードします。
5. ZIP内の `KiriPad-unsigned.ipa` を Sideloadly 等で自分の iPad 用に署名してインストールします。
6. KiriPad を起動し、ゲームフォルダを選びます。
7. `起動前プローブ` を押して静的なプラグイン情報を確認します。
8. `ランタイム起動` を押します。
9. 画面下のログに `startup FAILED`、`engine_open_game_async failed`、プラグイン名などが出たら、そのログを保存/スクリーンショットしてください。

Bundle ID は Phase 1 と同じ `dev.kiripad.phase1` を既定にしているため、同じ署名条件なら既存 KiriPad の更新として入れられ、Documents のゲームデータを引き継ぎやすい構成です。

## サノバウィッチについて

Phase 1診断では 28 個の DLL が確認されています。Phase 2A の優先度表示は「対応済み」の意味ではありません。実際のランタイムログで、起動時にどのプラグイン/APIが最初に必要になるかを特定するための目印です。

特に `yuzuex.dll`、D3D描画系、動画系は作品固有/Windows依存の可能性が高いため、Phase 2B以降の互換実装候補です。

## ゲームデータについて

- ゲーム本体を GitHub へアップロードする必要はありません。
- KiriPad はユーザーが選択したローカルフォルダを読みます。
- Phase 2A のプローブは XP3 を展開・復号・改変しません。
- DRM/コピー保護の解除を目的とする機能は含めません。

## KrKr2-Next とライセンス

実ランタイム Workflow は `https://github.com/reAAAq/KrKr2-Next` を取得してリンクします。KrKr2-Next は GPL-3.0-or-later で提供されています。
この Phase 2A ソースも、実ランタイムと組み合わせて配布しやすいよう GPL-3.0-or-later として扱います。自分以外へランタイム入りIPAを配布する場合は、対応するソースとライセンス提供条件を確認してください。

KiriPad のソースZIP自体には KrKr2-Next のバイナリやゲームデータは含めていません。

## ローカルテスト

Linux/macOS上でコアの単体テストのみ実行できます。

```bash
bash ./scripts/test_scanner.sh
```

iOS/Xcode ビルドは macOS が必要ですが、GitHub Actions の macOS runner で実行できます。

## 現段階の制限

- KrKr2-Next 自体の iOS 経路も開発中です。
- サノバウィッチの全 DLL 互換性は未実装です。
- 動画、D3D互換、作品固有拡張、フォント/音声などで追加作業が必要になる可能性があります。
- 実ランタイム版は「タイトル画面が必ず出る」ことを保証する版ではなく、次の互換実装に必要な **実起動ログを取る版** です。
