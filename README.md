[![test](https://github.com/ks6088ts/template-terraform/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/ks6088ts/template-terraform/actions/workflows/test.yml?query=branch%3Amain)

# template-terraform

A GitHub template repository for Terraform

## Scenarios

### Azure

| Scenario | Overview |
| --- | --- |
| [azure_terraform_backend](./infra/scenarios/azure_terraform_backend/README.md) | Terraform backend 用の Azure Storage Account を作成します。 |
| [azure_github_oidc](./infra/scenarios/azure_github_oidc/README.md) | GitHub Actions から Azure に OIDC で接続するための Service Principal を作成し、必要な権限を割り当てます。 |
| [azure_container_apps](./infra/scenarios/azure_container_apps/README.md) | Azure Container Apps をデプロイします。Docker Hub イメージを使用し、外部アクセス可能なコンテナアプリを作成します。 |
| [azure_datastore](./infra/scenarios/azure_datastore/README.md) | Azure のデータストア（Cosmos DB、Storage Account、Key Vault、PostgreSQL、Monitor）をデプロイします。テスト用途向けにパブリックアクセスを許可した構成です。 |
| [azure_microsoft_foundry](./infra/scenarios/azure_microsoft_foundry/README.md) | Azure 上に Microsoft Foundry 環境をデプロイします。Microsoft Foundry ワークロードを実行するためのインフラストラクチャをセットアップします。 |
| [azure_spoke_network](./infra/scenarios/azure_spoke_network/README.md) | Azure Hub-Spoke アーキテクチャ用の Spoke ネットワークをデプロイします。VNet、Bastion、Storage Account (Private Endpoint)、VM を構築します。 |
| [azure_inclusive_ai_labs](./infra/scenarios/azure_inclusive_ai_labs/README.md) | Azure Container Apps 上に azure_inclusive_ai_labs アプリケーションをデプロイします。VOICEVOX と連携した音声合成機能を持つ API サーバーを構築します。 |

### AWS

| Scenario | Overview |
| --- | --- |
| [aws_github_oidc](./infra/scenarios/aws_github_oidc/README.md) | GitHub Actions から AWS に OIDC で接続するための IAM ロールを作成し、必要な権限を割り当てます。 |

### GitHub

| Scenario | Overview |
| --- | --- |
| [github_secrets](./infra/scenarios/github_secrets/README.md) | GitHub リポジトリの環境シークレットを作成・管理します。GitHub Actions ワークフローで使用できます。 |

### その他

| Scenario | Overview |
| --- | --- |
| [hello_world](./infra/scenarios/hello_world/README.md) | Terraform の機能説明のための最小限のサンプル。random provider を使用してランダム文字列を生成します。 |
