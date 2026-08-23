---
title: Infracost によるクラウドコスト見積もり
description: Terraform のコストをローカルで見積もり、GitHub Actions で変更差分を確認する
ms.date: 2026-08-23
ms.topic: how-to
---

## インストールと認証

開発コンテナーには Infracost CLI と Infracost の VS Code 拡張機能がインストールされます。
`.devcontainer/devcontainer.json` の変更を取得した後、コンテナーをリビルドしてください。

コンテナー外で開発する場合は、プラットフォームに応じて CLI をインストールします。

```bash
# macOS
brew install infracost

# Linux
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Windows
choco install infracost
```

続いて一度だけ認証し、その他の開発ツールを確認します。

```bash
infracost auth login
make install-deps-dev
```

CLI はトークンをキャッシュするため、ローカルのコマンドは環境変数を設定しなくても動作します。
トークンをコミットしたり、リポジトリに保存するスクリプトからエクスポートしたりしないでください。

## ローカルでのコスト見積もり

リポジトリルートで次の 1 コマンドを実行し、検出されたすべてのプロジェクトを走査します。

```bash
make cost
```

このターゲットは走査サマリーに続けて、シナリオ名を省略せずに一覧表示し、各シナリオの月額コストを
出力します。課金対象のリソースがないシナリオは、この一覧には含まれません。単一シナリオの走査では
合計が 1 件しかないため、この一覧はリポジトリ全体を走査したときにのみ表示されます。

対象を 1 つのシナリオに限定する場合は、他のターゲットと同じ `SCENARIO` 変数を使用します。CLI の
フラグは `INFRACOST_ARGS` で渡します。

```bash
make cost SCENARIO=azure_container_apps
make cost INFRACOST_ARGS="--currency JPY"
```

再走査せずに直前の結果を確認するには、次のコマンドを使用します。

```bash
infracost inspect --failing
infracost inspect --top 10
```

## 結果の読み方

Infracost は Terraform コードを解析し、価格情報を取得します。クラウド資格情報は不要であり、
Terraform ステートの変更やクラウドリソースの作成は行いません。

出力は請求額の予測ではなく、設計時点の比較材料として扱ってください。

* ベースラインコストは 1 か月間の継続稼働を前提とします。検証のために 1 時間だけデプロイする
  場合、実際の費用は表示額のごく一部です。
* 従量課金コストは Infracost Cloud または `infracost-usage.yml` の利用量設定に依存します。
  このリポジトリのコストはベースライン資源が大半を占めるため、利用量ファイルは同梱していません。
  ストレージ、関数、データベースのリクエスト量を反映したい場合に追加してください。
* プロジェクトの検出は自動です。検出結果が誤っている場合にのみ `infracost.yml` を追加し、追加後は
  必ず再測定してください。静的なプロジェクト定義は変数ファイルの自動解決を上書きするため、コストと
  ポリシー検出の両方を気付かないうちに減らすことがあります。

このリポジトリのシナリオは参照実装であり、稼働中のインフラストラクチャではありません。そのため、
月額の絶対値よりも FinOps とタグポリシーの指摘の方が実用的です。既存の指摘は既知の未対応分として
扱い、シナリオを変更する際に、そのシナリオが報告する指摘を解消してください。

## GitHub Actions でのコストレビュー

`.github/workflows/infracost.yml` は、手動で実行したときにのみ起動します。Actions タブ、または
GitHub CLI から、レビュー対象の Pull Request 番号を指定して実行します。

```bash
gh workflow run infracost.yml -f pull_request_number=123
```

workflow は指定された Pull Request とそのベースブランチをチェックアウトし、コスト差分を
コメントします。手動実行にすることで、push のたびに実行されるのではなく、コストレビューを
明示的な操作として実行できます。リポジトリ全体のベースラインは意図的にアップロードしません。
これらのシナリオはデプロイされておらず、存在しないインフラストラクチャを計上してしまうためです。

Action と scanner のバージョンはいずれも固定しているため、実行結果は再現可能です。更新する際は
`INFRACOST_SCANNER_VERSION` と Action のコミットを合わせて変更してください。

認証情報は公式のセットアップフローで作成します。現行メジャーバージョンに適合するトークンが発行され、
`INFRACOST_API_KEY` という名前のリポジトリシークレットとして保存されます。

```bash
infracost ci setup
```

Infracost CLI 2.0 より前のバージョン向けに発行したトークンには互換性がありません。手動でシークレットを
設定する場合は、次のコマンドが値を対話的に受け取り、シェル履歴に残しません。

```bash
gh secret set INFRACOST_API_KEY
```

AWS、Azure、Google Cloud の資格情報は不要です。ただし workflow は、解析したコスト情報に加えて、
リポジトリ URL、Pull Request 番号、タイトル、作成者、ラベルなどのメタデータを Infracost Cloud へ
送信します。

手動実行はこのリポジトリのコンテキストで動作するため、fork からの Pull Request でも認証情報を利用でき、
同じ手順でレビューできます。Infracost は Terraform コードを解析するだけで Terraform を実行しませんが、
fork の変更内容を確認してから実行してください。

workflow はコストとポリシーの変更を報告しますが、予算の強制は行わず、手動実行の workflow は必須の
ステータスチェックにはできません。高額な変更を自動的にブロックするには、マージ前の承認を有効にした
Infracost Cost Guardrail を作成し、Infracost GitHub App または自動実行の workflow でステータスを
報告してください。

コスト見積もりは Infracost の認証情報を必要とするため、`make ci-test` には含めていません。認証不要の
静的解析（`terraform fmt`、`terraform validate`、TFLint、Trivy、actionlint）は `test` workflow が、
コストレビューは `infracost` workflow が担当します。

ローカル環境を診断するには、次のコマンドを実行します。

```bash
infracost doctor
```

## 一次情報

* [Infracost: Get started](https://www.infracost.io/docs/)
* [Infracost CLI commands](https://www.infracost.io/docs/features/cli_commands/)
* [Infracost environment variables](https://www.infracost.io/docs/features/environment_variables/)
* [Infracost config file](https://www.infracost.io/docs/features/config_file/)
* [Infracost GitHub Actions guide](https://www.infracost.io/docs/integrations/github_actions/)
* [Official Infracost GitHub Actions](https://github.com/infracost/actions)
* [Infracost Cost Guardrails](https://www.infracost.io/docs/infracost_cloud/guardrails/)
* [Infracost usage costs](https://www.infracost.io/docs/features/usage_based_resources/)
* [Infracost security and privacy FAQ](https://www.infracost.io/docs/faq/#security-and-privacy)
