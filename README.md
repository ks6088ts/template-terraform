[![test](https://github.com/ks6088ts/template-terraform/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/ks6088ts/template-terraform/actions/workflows/test.yml?query=branch%3Amain)

# template-terraform

A GitHub template repository for Terraform

## Scenarios

| Scenario | Overview |
| --- | --- |
| [hello_world](./infra/scenarios/hello_world/README.md) | Terraform の機能説明のための最小限のサンプル。random provider を使用してランダム文字列を生成します。 |
| [backend_azure_storage](./infra/scenarios/backend_azure_storage/README.md) | Terraform backend 用の Azure Storage Account を作成します。 |
| [service_principal](./infra/scenarios/service_principal/README.md) | Azure に接続するための Service Principal を作成し、必要な権限を割り当てます。 |
| [github_secrets](./infra/scenarios/github_secrets/README.md) | GitHub リポジトリの環境シークレットを作成・管理します。GitHub Actions ワークフローで使用できます。 |
| [azure_container_apps](./infra/scenarios/azure_container_apps/README.md) | Azure Container Apps をデプロイします。Docker Hub イメージを使用し、外部アクセス可能なコンテナアプリを作成します。 |
