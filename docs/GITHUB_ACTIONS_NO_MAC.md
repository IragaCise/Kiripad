# MacなしでKiriPadをビルドする

KiriPadは、手元にMacがなくても **GitHub ActionsのmacOSランナー** を使ってiPad用バイナリを生成できます。

このリポジトリの `.github/workflows/build-ios.yml` は次の処理を自動実行します。

1. Linux上で診断器のテスト
2. GitHubのmacOS環境でCMake/Xcodeプロジェクト生成
3. iPhoneOS向けARM64 Releaseビルド
4. `KiriPad.app` を作成
5. `KiriPad-unsigned.ipa` にパッケージ
6. GitHub ActionsのArtifactsへ保存

## 最短手順

### 1. GitHubに新しいリポジトリを作る

GitHubで空のリポジトリを1つ作成します。Public/Privateどちらでも構いません。

### 2. KiriPadのファイルをアップロード

このプロジェクト一式をリポジトリのルートへアップロードしてください。

最低でも次が同じ階層に見えていればOKです。

```text
.github/workflows/build-ios.yml
App/
Core/
Resources/
ci/
scripts/
CMakeLists.txt
```

### 3. Actionsを実行

GitHubで：

```text
Actions
  → Build KiriPad iOS
  → Run workflow
```

`iPad unsigned IPA` が成功すると、実行結果の **Artifacts** に次が出ます。

```text
KiriPad-unsigned-ipa
KiriPad-unsigned-app
```

`KiriPad-unsigned-ipa` をダウンロードすると、中に `KiriPad-unsigned.ipa` があります。

## なぜ「unsigned」なのか

iPad実機へインストールするアプリにはAppleのコード署名が必要です。
GitHub ActionsだけならXcodeビルドはできますが、あなた個人の署名証明書・Provisioning Profileを勝手に作ることはできません。

そのため、このPhaseではGitHub Actionsで **署名前のIPAまで自動生成** します。

その後、Windows上のiOSサイドロード/署名ツール等を使って、自分のApple IDで署名して自分のiPadへ入れる構成を想定しています。

有料Apple Developer Programの証明書とProvisioning Profileを用意できる場合は、同梱の署名付きワークフローで `signed IPA` をGitHub Actions内から直接生成できます。

## 無料Apple IDで使う場合

無料のPersonal Team相当の署名では、有効期間やアプリ数などApple側の制限があります。期限後は再署名・再インストールが必要になる場合があります。

KiriPad自体は、署名方式に依存しないよう作っています。

## ビルドに失敗した場合

GitHub Actionsの実行画面で `iPad unsigned IPA` → 失敗したステップを開き、ログを保存してください。

特に次を確認します。

```text
xcodebuild -version
CMake Error
CompileC / CompileCXX
Ld
error:
```

そのログをこちらに貼れば、次の修正に使えます。

## ゲームデータについて

ゲーム本体をGitHubへアップロードしないでください。
KiriPad本体だけをビルドし、ゲームデータはインストール後にiPadの「ファイル」から選択する設計です。


## オプション：署名付きIPAをGitHub Actionsで直接作る

Apple Developer Programの証明書（`.p12`）と対象iPadを含むProvisioning Profile（`.mobileprovision`）を用意できる場合は、`.github/workflows/build-ios-signed.yml` も使えます。

GitHubのリポジトリで `Settings → Secrets and variables → Actions` を開き、以下のRepository secretsを登録します。

```text
BUILD_CERTIFICATE_BASE64
P12_PASSWORD
BUILD_PROVISION_PROFILE_BASE64
KEYCHAIN_PASSWORD
APPLE_TEAM_ID
```

証明書とProvisioning ProfileはBase64文字列で登録します。秘密鍵を含む`.p12`やパスワードをリポジトリの通常ファイルとしてコミットしないでください。

登録後：

```text
Actions
  → Build Signed KiriPad iOS
  → Run workflow
```

`bundle_id` はProvisioning Profileに登録したApp IDと一致させます。`export_method` は通常、開発用プロファイルなら `debugging`、配布テスト用なら `release-testing` を選びます。

成功すると `KiriPad-signed-ipa` Artifactが生成されます。

GitHub-hosted runnerはジョブ終了時に破棄されますが、ワークフロー内でも一時KeychainとProvisioning Profileを削除します。
