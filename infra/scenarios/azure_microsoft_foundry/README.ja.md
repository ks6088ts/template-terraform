---
description: Terraform を使用して Azure に Microsoft Foundry 環境をデプロイする
---

# Azure Microsoft Foundry シナリオ

このシナリオでは、Terraform を使用して Azure に Microsoft Foundry 環境をデプロイします。
Foundry IQ の検索基盤として使用する Azure AI Search サービスと、Foundry プロジェクトに接続する
Azure Blob Storage アカウントも必要に応じてデプロイできます。

## アーキテクチャ

```mermaid
flowchart TB
    Internet((インターネット))

    subgraph Azure["Azure リソース グループ"]
        MF["Microsoft Foundry<br/>- アカウント<br/>- プロジェクト<br/>- モデル デプロイ"]
        Search["Azure AI Search<br/>（オプション）"]
        Storage["Azure Blob Storage<br/>（オプション）"]
    end

    Internet -->|HTTPS| MF
    Internet -.->|有効化した場合の HTTPS| Search
    Internet -.->|有効化した場合の HTTPS| Storage
    MF -->|プロジェクト接続<br/>API キー| Search
    MF -->|プロジェクト接続<br/>アカウント キー| Storage
```

## 前提条件

- Azure サブスクリプション
- 対象のサブスクリプションへサインイン済みの Azure CLI
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
`CognitiveSearch` 接続を作成します。AzAPI には write-only の `sensitive_body` を通じてキーを渡すため、
connection resource はキーの複製を state に保持しません。
一方、AzureRM の Search resource はプライマリ キーを機密性の高い state data として保持します。
暗号化されたリモート バックエンドを使用し、state の読み取りアクセスを必要な ID のみに制限してください。

Terraform は AzAPI を使用し、Azure Resource Manager のコントロール プレーンから接続を作成します。
[Foundry Connections API](https://ai.azure.com/api-reference/connections/list)では、作成された接続を
一覧表示および取得できますが、接続の作成はできません。

このオプションでは、ナレッジ ベース、ナレッジ ソース、インデックス、インデクサー、
またはエージェントは作成されません。

### Azure Blob Storage

`deploy_blob_storage` の既定値は `false` です。Azure Blob Storage アカウントをデプロイして
Microsoft Foundry プロジェクトに接続するには、環境固有の `terraform.tfvars` に次の値を追加します。

```hcl
deploy_blob_storage = true
```

Storage アカウントの構成はシナリオの入力として公開せず、固定しています。Standard/LRS、
階層型名前空間無効、public network endpoint 有効、HTTPS および TLS 1.2、匿名 Blob access 無効の
構成です。shared key 認証は有効で、Storage アカウントの managed identity および Blob soft delete は
無効です。

有効にすると、Terraform は Storage アカウントの primary access key を使用するプロジェクト スコープの
`AzureStorageAccount` connection を作成します。Azure Resource Manager の connection schema では
この認証方式を `AccountKey` と呼びます。これは Azure AI Search で使用する key-based の
`ApiKey` connection に相当する Storage 向けの認証方式です。AzAPI には write-only の
`sensitive_body` を通じてキーを渡すため、connection resource はキーの複製を state に保持しません。
一方、AzureRM の Storage resource は primary access key を機密性の高い state data として保持します。
暗号化された remote backend を使用し、state の読み取りアクセスを必要な ID のみに制限してください。

Azure AI Search connection と同様に、AzAPI を使用して Azure Resource Manager の
コントロール プレーンから作成します。Foundry プロジェクトの identity に対する role assignment は
作成しません。

このオプションでは、Blob container、queue、private endpoint、または private DNS zone は
作成されません。これらのリソースや private network path が必要な場合は、network を構成した
シナリオで共通の Storage module を使用してください。

### 破棄と purge

Microsoft Foundry アカウントを通常どおり削除すると、soft-delete されます。purge しない場合、
同じアカウント名を 48 時間再利用できません。このシナリオでは Terraform の destroy-time hook を登録し、
モデル デプロイ、プロジェクト、アカウントを削除した後、リソース グループを削除する前に
`az cognitiveservices account purge` を実行します。

> [!WARNING]
> purge は元に戻せません。アカウントに関連付けられたすべてのデータとキーが完全に削除されます。
> Terraform の実行 ID には、
> `Microsoft.CognitiveServices/locations/resourceGroups/deletedAccounts/delete` 権限が必要です。
> リソース グループ スコープの `Contributor` では不十分です。サブスクリプション スコープで
> `Cognitive Services Contributor` や `Contributor` などの適切なロールを割り当ててください。
> 詳細については、[削除された Microsoft Foundry リソースの復旧または消去](https://learn.microsoft.com/azure/ai-services/recover-purge-resources)を参照してください。

destroy の前に、purge action が Terraform state に存在する必要があります。この構成を追加または更新した後は、
最初の `terraform destroy` より前に `terraform apply` を一度実行してください。権限不足で purge に失敗した場合は、
権限を付与してから `terraform destroy` を再実行します。purge が成功するまで、アカウントは soft-delete 状態で残ります。

このシナリオのモデル デプロイでは、デプロイの競合を避けるため Terraform の処理を逐次実行する必要があります。
標準の Makefile によるデプロイおよび破棄コマンドには、`-parallelism=1` のオーバーライドが含まれていません。
`model_deployments` が空でない場合は、シナリオ ディレクトリから次のコマンドを直接実行します。

```bash
# デプロイを適用し、destroy 時の purge action を登録する
terraform apply -auto-approve -parallelism=1

# 出力を確認する
terraform output

# デプロイを破棄し、Foundry アカウントを完全に purge する
terraform destroy -auto-approve -parallelism=1
```
