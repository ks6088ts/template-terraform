---
description: Keyless な Microsoft Foundry Standard setup をデプロイし、Foundry IQ Prompt Agent を検証する
---

# Azure Microsoft Foundry シナリオ

このシナリオは、Azure に Microsoft Foundry account と project を 1 つずつデプロイします。リポジトリに
含まれる構成では、利用者管理の Storage、Azure AI Search、Cosmos DB を使う public endpoint の
[Standard setup](https://learn.microsoft.com/azure/foundry/agents/concepts/standard-agent-setup)を
有効にします。Local key は無効化し、Microsoft Entra ID、managed identity、Azure RBAC を使用します。

Terraform の完了後、1 つの command で架空の飲食店レビューを upload し、次の経路全体を検証できます。

```text
Blob Storage -> Foundry IQ knowledge source -> knowledge base -> MCP connection
             -> Prompt Agent -> 参照付きの grounded answer
```

任意の server-side tracing では OpenTelemetry span を workspace-based Application Insights に送信します。

> [!IMPORTANT]
> これは学習用シナリオであり、production landing zone ではありません。Public endpoint と preview の
> Foundry IQ、RemoteTool、identity-based tracing を使用します。デプロイ前に
> [境界とコスト](#境界とコスト)を確認してください。

## クイック スタート

### 前提条件

- Terraform **1.11 以降**
- Azure CLI **2.50 以降**、`curl`、`jq`、POSIX 互換 shell
- リソースと role assignment を作成できる Azure subscription
- Foundry Agent Service、Foundry IQ、選択した 2 model をサポートする Japan East または別 region
- 選択した SKU と capacity に十分な model quota

共通の [Azure 認証](../../../docs/tips/provider-authentication.ja.md)と
[Terraform workflow](../../../docs/tips/terraform-workflow.ja.md)に従ってください。既定 backend は
このリポジトリ用の Azure Blob backend です。リポジトリ外で使う場合は変更してください。

### 1. Sign-in と構成の確認

```bash
az login
az account set --subscription "<subscription-name-or-id>"
cd infra/scenarios/azure_microsoft_foundry

terraform init
terraform validate
terraform plan
```

`operator_principal_id` は Terraform 実行 principal の object ID を既定で使用します。デプロイ後の script
を別 principal が実行する場合だけ上書きします。

```bash
terraform plan -var="operator_principal_id=<entra-object-id>"
```

Apply 前に model の提供状況と quota を確認してください。既定 capacity の単位は 1,000 token/minute です。

### 2. Infrastructure のデプロイ

Azure model deployment は同時作成時に競合する場合があるため、Terraform を逐次実行します。

```bash
terraform apply -parallelism=1
terraform output
```

### 3. End-to-end 検証

```bash
./scripts/run_all.sh
```

この command は次の gate の最初の失敗で停止します。

1. 必要な tool、Terraform output、login、token audience、model deployment が存在する
2. **新しい** Search ingestion run が 1 item 以上を処理し、失敗 0 で完了する
3. Knowledge base の direct retrieval が content と 1 件以上の grounding reference を返す
4. Prompt Agent が text と 1 件以上の MCP event を返す

REST response 全体を表示するには `VERBOSE_OUTPUT=true` を設定します。成功時または失敗時に
script 作成データを削除する場合は次を実行します。

```bash
CLEANUP_AFTER_RUN=true ./scripts/run_all.sh
```

### 4. Cleanup

Script が作成した resource だけを削除します。

```bash
CONFIRM_CLEANUP=delete-foundry-iq-resources ./scripts/09_cleanup.sh
```

続いて Terraform 管理 infrastructure を破棄します。

```bash
terraform destroy -parallelism=1
```

Destroy は soft-delete された Foundry account を完全に purge します。そのため Terraform 実行 identity
には、subscription scope で
`Microsoft.CognitiveServices/locations/resourceGroups/deletedAccounts/delete` が必要です。
適切な `Cognitive Services Contributor` または `Contributor` などを使用してください。Purge は
取り消せません。

## デプロイされるもの

```mermaid
flowchart TD
    Operator["Terraform / script Operator"]
    RG["Resource group"]
    Account["Microsoft Foundry account<br/>system identity / local auth 無効"]
    Project["Foundry project<br/>system identity"]
    Chat["gpt-5.4-mini deployment"]
    Embedding["text-embedding-3-large deployment"]
    Search["Azure AI Search<br/>system identity / local auth 無効"]
    Storage["StorageV2 / ZRS<br/>shared key 無効"]
    Cosmos["Cosmos DB for NoSQL<br/>Session consistency / local auth 無効"]
    AccountHost["Account capability host"]
    ProjectHost["Project capability host"]
    Insights["Application Insights + Log Analytics<br/>任意"]
    Scripts["Foundry IQ scripts"]

    Operator --> RG
    RG --> Account
    Account --> Project
    Account --> Chat
    Account --> Embedding
    RG --> Search
    RG --> Storage
    RG --> Cosmos
    Account --> AccountHost
    Project --> ProjectHost
    ProjectHost --> Search
    ProjectHost --> Storage
    ProjectHost --> Cosmos
    Operator --> Scripts
    Scripts --> Storage
    Scripts --> Search
    Scripts --> Project
    Search --> Storage
    Search --> Embedding
    Project -. "trace" .-> Insights
```

Terraform は Azure resource、connection、role assignment、capability host を管理します。Script が管理する
のは sample Blob container/file、Search knowledge object、RemoteTool connection、Prompt Agent version、
一時 conversation だけです。

### 既定の model deployment

Workflow が使う model だけをデプロイします。

| Deployment / model | Version | SKU | Capacity | Version upgrade |
| --- | --- | --- | ---: | --- |
| `gpt-5.4-mini` | `2026-03-17` | `GlobalStandard` | 100 | `NoAutoUpgrade` |
| `text-embedding-3-large` | `1` | `GlobalStandard` | 30 | `NoAutoUpgrade` |

Model の提供状況、許容 capacity 増分、quota、Agent Service 互換性は region と subscription に依存します。
必要に応じて `model_deployments` を上書きしてください。`GlobalStandard` は resource region 外で request を
処理する場合があります。Data residency が必要な場合は data-zone または regional deployment type を
使用してください。

### 主な input

| Input | Default | 用途 |
| --- | --- | --- |
| `location` | `japaneast` | Azure region |
| `enable_standard_setup` | `true` | 利用者管理の Search、Storage、Cosmos DB、connection、capability host を作成 |
| `azure_ai_search_sku` | `standard` | Search tier。`basic` とサポート対象の上位 tier を指定可能 |
| `enable_tracing` | `false` | Entra-only Application Insights tracing を追加 |
| `operator_principal_id` | Terraform principal | Script 実行を許可する principal |
| `enable_operator_cosmosdb_read_access` | `false` | `enterprise_memory` の read-only 調査権限を追加 |
| `model_deployments` | 上記 2 行 | Model、version、SKU、capacity、upgrade 動作 |

既定値ではシナリオ全体を構築します。Foundry account、project、model deployment だけが必要な場合は、
自身の variable file で `enable_standard_setup = false` を指定します。

`deploy_standard_agent` は削除しました。既存 variable file は次のように変更してください。

```hcl
# 変更前
deploy_standard_agent = true

# 現在
enable_standard_setup = true
```

### 主な output

Script は `terraform output -json` を自動的に読み取ります。利用者が確認しやすい output は次のとおりです。

- Foundry account 名と OpenAI endpoint
- Foundry project 名、resource ID、project endpoint
- Model deployment ID
- Search、Storage、Cosmos DB の名前と endpoint
- Capability host と project connection の ID
- 任意の Log Analytics と Application Insights の ID

Endpoint は公開 resource identifier であり credential ではありません。Terraform state や診断 output 全体を
公開しないでください。

## Security と認可

このシナリオの認証経路はすべて keyless です。

- Foundry、Search、Storage、Cosmos DB の local/key authentication を無効化
- Standard store connection は `authType = "AAD"` を使用
- Foundry IQ RemoteTool connection は `ProjectManagedIdentity` を使用
- Tracing は `ProjectManagedIdentity` と local authentication 無効の Application Insights を使用
- Script は ARM、Storage、Search、Foundry ごとに Azure CLI token を取得

主な role assignment は次のとおりです。

| Assignee | Scope | Role |
| --- | --- | --- |
| Project identity | Storage account | Storage Account Contributor |
| Project identity | Project file container pattern | Storage Blob Data Contributor |
| Project identity | Project agent container pattern | Storage Blob Data Owner |
| Project identity | Search service | Search Service Contributor、Search Index Data Contributor |
| Project identity | Cosmos DB account / `enterprise_memory` | Cosmos DB Operator、Cosmos DB Built-in Data Contributor |
| Project identity | Foundry account | Foundry User |
| Search identity | Source Storage / Foundry account | Storage Blob Data Reader、Cognitive Services User |
| Operator | Sample Storage / Search | Storage Blob Data Contributor、Search Service Contributor、Search Index Data Contributor |
| Operator | Foundry account | Foundry User、Foundry Project Manager |

Storage data role は account scope で割り当てますが、Azure ABAC condition によって project 内部 workspace ID
を prefix とする service-managed container suffix だけへ制限します。Data Contributor に必要な read が
含まれるため、Search Index Data Reader は重複して追加しません。

任意の Cosmos 調査権限は account の ARM `Reader` と `enterprise_memory` だけの Cosmos DB Built-in Data
Reader です。Agent state には prompt、response、conversation state、Agent metadata が含まれる可能性が
あるため、信頼できる Operator だけに付与してください。

## Standard setup の互換性

このシナリオは stable ARM API `2026-07-01` の account/project capability host を使用します。Microsoft は
現在 `capabilitySettings` を推奨していますが、この preview は現時点で UK South と Canada Central に
限定されています。既定の Japan East では capability host がサポート対象経路です。

AzAPI 2.13 は `2026-07-01` schema をまだ内蔵していないため、公式に記載されたこれらの Foundry ARM
resource だけ embedded provider validation を無効化しています。Provider schema が追従するまで Terraform
mock test で resource type と payload を検証します。

Capability host は account/project scope ごとに 1 つだけ作成でき、更新できません。Terraform は設定値が
変わると replacement し、固定 sleep の代わりに既知の一時的な authorization/provisioning error を
bounded retry します。

Project identity は次の利用者管理 resource にアクセスします。

- Agent file 用 Storage
- Vector store 用 Search
- Agent state 用 Cosmos DB `enterprise_memory`

Connection は secret を保持しないため Key Vault は作成しません。Private endpoint と BYO VNet も対象外です。

## Foundry IQ / Prompt Agent workflow

### 主 command

[`scripts/run_all.sh`](./scripts/run_all.sh) は連番 script を順番に実行します。問題の切り分けや高度な設定時だけ
個別 step を実行してください。

| Script | 処理 |
| --- | --- |
| `00_validate_prerequisites.sh` | Tool、output、model、login、token audience を検証 |
| `01_upload_restaurant_reviews.sh` | Private container を作成して CSV を upload |
| `02_create_knowledge_source.sh` | Keyless Blob knowledge source を作成/更新 |
| `03_wait_for_ingestion.sh` | 新しい generated-indexer run を選択または開始して完了を検証 |
| `04_create_knowledge_base.sh` | Extractive knowledge base を作成/更新 |
| `05_retrieve_knowledge_base.sh` | Direct retrieval の grounding content/reference を必須化 |
| `06_create_project_connection.sh` | Managed identity RemoteTool connection を作成/更新 |
| `07_create_agent.sh` | MCP 対応 Prompt Agent の新 version を作成 |
| `08_ask_agent.sh` | Answer と MCP event を必須化し、一時 conversation を削除 |
| `09_cleanup.sh` | Script 作成 resource を削除し、Search の削除完了を待機 |

Blob knowledge source は sample CSV を 1 source file として扱うため、reference は CSV row 単位ではなく
file 単位です。データは架空です。

### API version

| Surface | Version |
| --- | --- |
| Foundry ARM account/project/deployment/connection/capability host | `2026-07-01` |
| Azure AI Search data plane / MCP endpoint | `2026-08-01-preview` |
| Foundry RemoteTool project connection | `2025-10-01-preview` |
| Foundry Agent Service | `v1` |
| Azure Storage data plane | `2026-04-06` |

### Script の上書き

| Environment variable | Default |
| --- | --- |
| `RESTAURANT_DATA_FILE` | `data/restaurant_reviews.csv` |
| `CONTAINER_NAME` / `BLOB_NAME` | `restaurant-reviews` / `restaurant_reviews.csv` |
| `KNOWLEDGE_SOURCE_NAME` / `KNOWLEDGE_BASE_NAME` | `restaurant-reviews-ks` / `restaurant-reviews-kb` |
| `PROJECT_CONNECTION_NAME` / `AGENT_NAME` | `restaurant-reviews-kb-mcp` / `restaurant-qa-agent` |
| `AGENT_MODEL` | `gpt-5.4-mini` |
| `EMBEDDING_DEPLOYMENT` / `EMBEDDING_MODEL` | `text-embedding-3-large` |
| `INGESTION_TIMEOUT_SECONDS` / `POLL_INTERVAL_SECONDS` | `900` / `10` |
| `CLEANUP_TIMEOUT_SECONDS` | `300` |
| `KEEP_CONVERSATION` | `false` |
| `CLEANUP_AFTER_RUN` | `false` |
| `VERBOSE_OUTPUT` | `false` |

Knowledge source、knowledge base、connection、Blob upload は同名で再実行できます。Agent 作成は同名 Agent の
新 version を追加します。Q&A script は既定で conversation を削除します。調査のために残す場合は
`KEEP_CONVERSATION=true` を設定し、その ID を cleanup に渡します。

```bash
KEEP_CONVERSATION=true ./scripts/08_ask_agent.sh
CONVERSATION_ID="<id>" \
  CONFIRM_CLEANUP=delete-foundry-iq-resources \
  ./scripts/09_cleanup.sh
```

## Tracing

Plan と apply の両方で tracing を有効にします。

```bash
terraform plan -var="enable_tracing=true"
terraform apply -parallelism=1 -var="enable_tracing=true"
```

Terraform は 30 日保持の Log Analytics workspace、workspace-based Application Insights、
project-scope の `AppInsights` connection、必要な role を作成します。Agent request 後 2 から 5 分待ち、
Microsoft Foundry の **Agents > Traces** を確認してください。

Identity-based trace ingestion は preview です。Trace には prompt、model input/output、tool
argument/result、latency、token 使用量、error が含まれる可能性があります。有効化前に privacy、retention、
access 要件を適用してください。

## 境界とコスト

- Public endpoint を有効にします。Microsoft Entra 認証は key を排除しますが network traffic を分離しません。
- Search は既定で Standard/S1、1 replica です。Sample には十分ですが query SLA はありません。Public
  keyless path では Basic も指定できます。Private Blob execution に必要な S2 以上は対象外です。
- Semantic ranker と agentic retrieval は別々の月次無料枠から開始します。無料枠を超えると、それぞれの
  Standard pay-as-you-go plan を有効にしない限り billing error になります。
- Cosmos DB は provisioned throughput を使います。Microsoft の account 最低要件は 3,000 RU/s です。
  New runtime は 1,000 RU/s container を 2 つ使い、classic compatibility ではさらに 3 つ追加されるため、
  両方を使う場合は project ごとに最大 5,000 RU/s を想定します。
- Storage、Search、Cosmos DB、model token、trace ingestion/retention に料金が発生する可能性があります。
- Private network、Key Vault/CMK、alert、dashboard、application UI、document-level ACL passthrough、
  application 固有の Responsible AI/evaluation test は対象外です。

## トラブルシューティング

- **Model deployment 失敗:** Region、version、SKU、capacity 増分、quota を確認します。
- **Capability host 失敗:** 上記 project identity role と RBAC 伝播を確認します。Retry は 30 分の create
  timeout で終了します。
- **Blob `403`:** Operator の Blob Data Contributor と Search identity の Blob Data Reader を確認します。
- **Search `401`/`403`:** Operator の Search Service Contributor と Search Index Data Contributor を確認します。
- **Ingestion 失敗:** Step `03` の item error を確認します。古い完了 run を成功扱いしません。
- **Retrieval billing error:** Semantic ranker と Knowledge retrieval の両 plan を確認します。
- **MCP `400`/`404`:** Knowledge base 名と `2026-08-01-preview` の slash-style MCP endpoint を確認します。
- **Agent/connection `403`:** Operator の Foundry User/Foundry Project Manager と project identity の
  Foundry User を確認します。
- **Trace なし:** `AppInsights` connection が 1 つであること、Monitoring Metrics Publisher、local auth
  無効、2 から 5 分の遅延を確認します。
- **Cosmos Data Explorer `403`:** 任意の read access を有効にし、Entra ID RBAC login を使用します。

## Contributor 向け検証

Repository check に Azure access は不要です。

```bash
terraform init -backend=false
terraform fmt -check
terraform validate
terraform test
./scripts/tests/test_scripts.sh
```

Offline script test は Terraform、Azure CLI、REST call を stub します。Fresh ingestion の選択、partial
retrieval、grounding/MCP gate、一時 conversation cleanup、Search cleanup polling を検証します。

## 参考資料

- [Microsoft Foundry](https://learn.microsoft.com/azure/foundry/what-is-foundry)
- [Foundry Agent Service Standard setup](https://learn.microsoft.com/azure/foundry/agents/concepts/standard-agent-setup)
- [Capability host](https://learn.microsoft.com/azure/foundry/agents/concepts/capability-hosts)
- [Capability settings](https://learn.microsoft.com/azure/foundry/how-to/configure-capability-settings)
- [Agent と Foundry IQ の接続](https://learn.microsoft.com/azure/foundry/agents/how-to/foundry-iq-connect)
- [Blob knowledge source](https://learn.microsoft.com/azure/search/agentic-knowledge-source-how-to-blob)
- [Agentic retrieval](https://learn.microsoft.com/azure/search/agentic-retrieval-overview)
- [Foundry RBAC](https://learn.microsoft.com/azure/foundry/concepts/rbac-foundry)
- [Microsoft Entra ID による trace ingestion](https://learn.microsoft.com/azure/foundry/observability/how-to/trace-ingestion-entra-authentication)
- [Foundry model deployment type](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/deployment-types)
- [Azure OpenAI quota と制限](https://learn.microsoft.com/azure/foundry/openai/quotas-limits)
- [Azure AI Search API version](https://learn.microsoft.com/azure/search/search-api-versions)
- [Cosmos DB data-plane role](https://learn.microsoft.com/azure/cosmos-db/reference-data-plane-security)
