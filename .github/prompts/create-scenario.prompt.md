---
agent: 'agent'
description: '新規 Terraform シナリオを作成する'
---

# Terraform シナリオ作成

新しい Terraform シナリオを作成します。既存シナリオをベースにすることも、ゼロから作成することも可能です。

## 入力情報

シナリオ名: ${input:scenarioName:シナリオ名を入力してください（例: azure_redis, aws_lambda）}
ベースシナリオ: ${input:baseScenario:参考にする既存シナリオ名（新規作成の場合は空欄）}
追加要件: ${input:requirements:追加の要件を記載してください}

## 実行内容

以下の手順でシナリオを作成してください：

1. **シナリオディレクトリの作成**: `infra/scenarios/${input:scenarioName}/` 配下に以下のファイルを作成
   - `main.tf` - メインのリソース定義
   - `variables.tf` - 変数定義
   - `outputs.tf` - 出力定義
   - `providers.tf` - プロバイダ設定
   - `versions.tf` - Terraform バージョン制約
   - `backend.tf` - バックエンド設定
   - `README.md` - シナリオの説明

2. **モジュールの作成**: 必要に応じて `infra/modules/{provider}/` 配下にモジュールを作成

3. **CI テストの追加**: `.github/workflows/test.yml` に CI テストを追加

4. **README の更新**: ルートの `README.md` にシナリオを追記

## ベースシナリオの選び方

| 新規シナリオの種類 | 推奨ベースシナリオ |
|---|---|
| Azure リソース全般 | `azure_container_apps` |
| GitHub OIDC 連携 | `azure_github_oidc`, `aws_github_oidc` |
| ネットワーク構成 | `azure_spoke_network` |
| データストア | `azure_datastore` |
| シンプルな検証 | `hello_world` |

## 注意事項

- 設定変更が想定されるパラメータは変数として隔離する
- デフォルト値を適切に設定する
- 他のシナリオと命名規則を統一する（例: `azure_*`, `aws_*`, `google_*`, `github_*`）
- 不明点がある場合は実装に着手せず質問を返す
- 参照情報（cdk.tf、compose.yml など）があれば明示する
- resource は可能な限りモジュール化する
- README.md には概要、入力変数、出力変数、特徴、利用例、参照リンクを含める
- シナリオ、モジュール双方で必ず `variables.tf`, `outputs.tf`, `versions.tf` を作成する
- `export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv) && make fix _ci-test-base SCENARIO=${input:scenarioName}` コマンドで CI テストが通過することを確認する

## 参照ファイル

既存の実装パターンを参照：
- `infra/scenarios/` - 既存シナリオの実装例
- `infra/modules/` - 再利用可能なモジュール
- `.github/workflows/test.yml` - CI テスト設定
