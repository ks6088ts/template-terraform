---
description: Terraform を使用して Azure に Microsoft Foundry 環境をデプロイする
---

# Azure Microsoft Foundry シナリオ

このシナリオでは、Terraform を使用して Azure に Microsoft Foundry 環境をデプロイします。
Foundry IQ の検索基盤として使用する Azure AI Search サービスも必要に応じてデプロイできます。

## アーキテクチャ

```mermaid
flowchart TB
    Internet((インターネット))

    subgraph Azure["Azure リソース グループ"]
        MF["Microsoft Foundry<br/>- アカウント<br/>- プロジェクト<br/>- モデル デプロイ"]
        Search["Azure AI Search<br/>（オプション）"]
    end

    Internet -->|HTTPS| MF
    Internet -.->|有効化した場合の HTTPS| Search
    MF -->|プロジェクト接続<br/>API キー| Search
```

## 前提条件

- Azure サブスクリプション
- Terraform 1.11 以降

共通の [Azure 認証](../../../docs/tips/provider-authentication.ja.md)、
[Terraform ワークフロー](../../../docs/tips/terraform-workflow.ja.md)、および必要に応じて
[Azure Blob Storage バックエンド](../../../docs/tips/azure-blob-backend.ja.md)のガイダンスに従ってください。
リポジトリの Makefile を使用する場合は、`SCENARIO=azure_microsoft_foundry` を設定します。

## 使用方法

### モデル デプロイ

既定では、Microsoft Foundry アカウントに次のモデルをデプロイします。

| デプロイ名およびモデル | バージョン | SKU | Capacity |
| --- | --- | --- | ---: |
| `gpt-5.6-luna` | `2026-07-09` | `GlobalStandard` | 1000 |
| `gpt-5.6-terra` | `2026-07-09` | `GlobalStandard` | 1000 |
| `gpt-5.6-sol` | `2026-07-09` | `GlobalStandard` | 1000 |
| `gpt-5.4-mini` | `2026-03-17` | `GlobalStandard` | 1000 |
| `text-embedding-3-large` | `1` | `GlobalStandard` | 3000 |
| `text-embedding-3-small` | `1` | `GlobalStandard` | 3000 |

適用前に `model_deployments` を確認し、対象のサブスクリプションおよびリージョンで利用できる
モデル、バージョン、capacity、クォータに合わせて上書きしてください。モデルをデプロイせずに
アカウントとプロジェクトだけを作成する場合は、空のリストを指定します。

```hcl
model_deployments = []
```

### Azure AI Search

`deploy_azure_ai_search` の既定値は `false` です。Azure AI Search をデプロイして
Microsoft Foundry プロジェクトに接続するには、環境固有の `terraform.tfvars` に次の値を追加します。

```hcl
deploy_azure_ai_search = true
azure_ai_search_sku    = "free"
```

別のサポート対象 tier を使用する場合は、`azure_ai_search_sku` に `basic`、`standard`、
`standard2`、`standard3`、`storage_optimized_l1`、または `storage_optimized_l2` を指定します。
利用可否とクォータ要件は、サブスクリプションおよびリージョンによって異なります。

> [!NOTE]
> Azure AI Search の既定 SKU には、Foundry IQ の概念実証向けに案内されている
> 最小コストの `free` を使用します。
> 詳細については、[Azure AI Search の Terraform クイックスタート](https://learn.microsoft.com/en-us/azure/search/search-get-started-terraform)、
> [Foundry IQ の概要](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/what-is-foundry-iq)、
> [Azure AI Search の stable REST API 仕様](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/search/data-plane/Search/stable)、および
> [Microsoft Foundry プロジェクト接続の ARM スキーマ](https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts/projects/connections)を参照してください。

有効にすると、Terraform は Azure AI Search のプライマリ管理キーを使用するプロジェクト スコープの
`CognitiveSearch` 接続を作成し、すべてのプロジェクト ユーザーと共有します。AzAPI には write-only の
`sensitive_body` を通じてキーを渡すため、connection resource はキーの複製を state に保持しません。
一方、AzureRM の Search resource はプライマリ キーを機密性の高い state data として保持します。
暗号化されたリモート バックエンドを使用し、state の読み取りアクセスを必要な ID のみに制限してください。

Terraform は AzAPI を使用し、Azure Resource Manager のコントロール プレーンから接続を作成します。
[Foundry Connections API](https://ai.azure.com/api-reference/connections/list)では、作成された接続を
一覧表示および取得できますが、接続の作成はできません。

このオプションでは、ナレッジ ベース、ナレッジ ソース、インデックス、インデクサー、
またはエージェントは作成されません。

このシナリオのモデル デプロイでは、デプロイの競合を避けるため Terraform の処理を逐次実行する必要があります。
標準の Makefile によるデプロイおよび破棄コマンドには、`-parallelism=1` のオーバーライドが含まれていません。
`model_deployments` が空でない場合は、シナリオ ディレクトリから次のコマンドを直接実行します。

```bash
# デプロイを適用する
terraform apply -auto-approve -parallelism=1

# 出力を確認する
terraform output

# デプロイを破棄する
terraform destroy -auto-approve -parallelism=1
```
