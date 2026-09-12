# KiriPad Phase 1

iPad上で吉里吉里系ゲームの互換ランタイムを作るための最初の開発キットです。
最初の基準作品は **サノバウィッチ**、次段階で **みるくふぁくとりーのスパイ学園** を対象にする想定です。

## Phase 1でできること

- iPadの「ファイル」からゲームフォルダを選択
- セキュリティスコープ付きURL経由でフォルダを読む
- `data.xp3` / `startup.tjs` / `patch.tjs` / `config.tjs` を検出
- XP3 / TJS / KAG(KS) / DLL / TPM / EXE / 動画 / 音声をカウント
- Windowsネイティブプラグイン候補を表示
- ゲームデータの展開、復号、改変は行わない

**まだゲーム本編は起動しません。** Phase 1は「何が足りないかを正確に測る」ための土台です。

## 必要なもの

### Macを使う場合

- macOS
- Xcode（現在の安定版を推奨）
- CMake 3.21以上
- Apple ID（実機署名用）
- iPad（iPadOS 15以上を当面の最低ラインに設定）

### Macを持っていない場合

- GitHubアカウント
- Windows PCなど、GitHubを操作できる環境
- iPad

`.github/workflows/build-ios.yml` を追加済みです。GitHub ActionsのmacOSランナーでXcodeビルドし、`KiriPad-unsigned.ipa` をArtifactsから取得できます。詳しくは `docs/GITHUB_ACTIONS_NO_MAC.md` を参照してください。


## 0. Macなし：GitHub ActionsでIPAを作る

このプロジェクトをGitHubへアップロードし、

```text
Actions → Build KiriPad iOS → Run workflow
```

を実行すると、GitHubのmacOS環境でビルドされます。成功後のArtifactsから `KiriPad-unsigned-ipa` を取得できます。

これは **unsigned IPA** です。実機インストール前に自分のApple ID/証明書で署名する必要があります。ゲームデータはGitHubへアップロードしません。

詳細：`docs/GITHUB_ACTIONS_NO_MAC.md`

Apple Developer Programの証明書とProvisioning Profileを用意できる場合は、`Build Signed KiriPad iOS` ワークフローで署名済みIPAの生成にも対応しています。

## 1. まず診断器をローカルでテスト

```bash
./scripts/test_scanner.sh
```

成功すると `scanner tests passed` と表示され、`.build-tools/kiripad-inspect` が生成されます。
PC上のゲームフォルダを診断する例：

```bash
./.build-tools/kiripad-inspect "/path/to/game"
```

## 2. iPadアプリのXcodeプロジェクトを生成

```bash
./scripts/generate_xcode.sh
```

Xcodeが開いたら：

1. `KiriPad` target → Signing & Capabilities
2. Development Teamを自分のApple ID/Teamに設定
3. 接続したiPadをRun Destinationに選択
4. Run
5. 「ゲームフォルダを選択」から、自分が正規に所有するゲームのフォルダを選ぶ

## 3. 吉里吉里SDL2の純粋なiOSビルドも確認

```bash
./scripts/bootstrap_krkrsdl2_ios.sh
```

これはKiriPadとは別に、上流の吉里吉里SDL2がそのMac/Xcode/iPadでビルドできるかを確認するための基準試験です。
上流はiOS向けCMake/Xcode生成を持っていますが、未変更の市販ゲーム実行はサポート対象外と明記しています。

## なぜ先に診断するのか

サノバウィッチが起動しない場合でも、原因は複数あります。

- 標準吉里吉里API不足
- Windows DLL/TPMプラグイン
- XP3フィルタや独自アーカイブ処理
- 動画コーデック
- フォント
- ファイル名の大文字小文字
- DirectX/GDI依存描画
- ライセンス/DRM

最初から全部を実装すると切り分け不能になるため、Phase 1でゲーム構成を記録し、Phase 2で必要な互換APIだけ追加します。

## 次の完成条件（Phase 2）

1. C/C++のエンジンAPIをKiriPadへリンク
2. 選択フォルダをエンジンのストレージルートとして渡す
3. TJS初期化
4. タイトル画面描画
5. タッチ → マウスイベント変換
6. 音声初期化

最初のゴールは **「サノバウィッチのタイトル画面をiPadに出す」** です。

## 参考エンジンを取得

```bash
./scripts/fetch_reference_engines.sh
```

- `KrKr2-Next`: **Phase 2の第一実装候補**。C APIの橋渡しとiOS経路が既にあり、Metal系の作業も進行中
- `Kirikiroid2`: 市販ゲーム互換の実装参考。過去にiOS版の実績があるが、公開ソース側のiOS構成は古い
- `krkrsdl2`: iOSネイティブビルドが成立するかを見る基準実装。商用ゲームの無変更実行は上流サポート外

各プロジェクトのライセンスを必ず確認してください。本キットはそれらのソースを同梱していません。

## 重要

このプロジェクトは互換性研究・個人所有ソフトの実行基盤を目的としています。
コピー保護やDRMを回避するコードはPhase 1には含めていません。
