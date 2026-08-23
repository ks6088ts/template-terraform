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

`.github/workflows/infracost.yml` は、同一リポジトリからの Pull Request が作成、更新、または
再オープンされたときに自動実行されます。Pull Request の head をチェックアウトし、固定バージョンの
Infracost CLI をインストールして、ローカルと同じ `make cost` コマンドを実行します。`Estimate costs`
ステップのログには、リポジトリ全体の走査サマリー、FinOps とタグポリシーの指摘、シナリオ別の月額
コストが出力されます。

明示的に試算する場合は、Actions タブでブランチを選択するか、GitHub CLI にブランチを指定して
実行します。

```bash
gh workflow run infracost.yml --ref feature/example
```

workflow は push や閉じられた Pull Request では実行しません。Pull Request の head に対する試算を
出力し、デフォルトブランチのベースライン維持やコスト差分コメントの投稿は行いません。

workflow は固定した CLI リリースをダウンロードし、公式の SHA-256 チェックサムを検証してから
インストールします。`INFRACOST_VERSION` を更新する前に、互換性を確認してください。

認証情報は公式のセットアップフローで作成します。現行メジャーバージョンに適合するトークンが発行され、
`INFRACOST_API_KEY` という名前のリポジトリシークレットとして保存されます。

```bash
infracost ci setup --ci-pipeline
```

Infracost CLI 2.0 より前のバージョン向けに発行したトークンには互換性がありません。手動でシークレットを
設定する場合は、次のコマンドが値を対話的に受け取り、シェル履歴に残しません。

```bash
gh secret set INFRACOST_API_KEY
```

AWS、Azure、Google Cloud の資格情報は不要です。workflow は CLI が対応する非対話認証用の環境変数を
介してリポジトリシークレットを渡し、`make cost` は解析したコスト情報を Infracost Cloud へ送信します。

GitHub は fork または Dependabot の Pull Request をトリガーとする workflow にリポジトリシークレットや
書き込みトークンを渡さないため、自動実行のジョブでは対象外にします。Dependabot の変更内容を確認した
後、そのブランチを選択して workflow を手動実行してください。fork のブランチは `workflow_dispatch` で
選択できないため、確認済みの fork をローカルへチェックアウトして `make cost` を実行します。Infracost は
Terraform コードを解析するだけで Terraform を実行しませんが、必ず未信頼の変更内容を確認してから
走査してください。

workflow の出力は情報提供のみです。Actions のログへ試算コストとポリシーの指摘を出力しますが、
予算の強制や Pull Request コメントの投稿は行いません。コスト差分コメントと Infracost Cost Guardrail
のステータスチェックが必要な場合は、Infracost GitHub App または専用の diff 連携を使用してください。

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
