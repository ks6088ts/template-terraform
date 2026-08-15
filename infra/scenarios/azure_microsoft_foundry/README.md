---
description: Deploy a Microsoft Foundry environment on Azure with Terraform
---

# Azure Microsoft Foundry Scenario

This scenario deploys a Microsoft Foundry environment on Azure using Terraform.
It can also deploy the bring-your-own data services and capability hosts required
for Foundry Agent Service Standard setup. Microsoft Entra ID and the Foundry
project managed identity are used instead of resource keys. Numbered POSIX shell
scripts can then upload a fictional restaurant review dataset, create a Foundry
IQ knowledge source and knowledge base, connect them to a prompt agent over MCP,
and run grounded Q&A.

## Concepts used in this README

This section defines the terms needed to follow the scenario without requiring
prior Microsoft Foundry context. Product and API object names remain in English
so that they can be matched directly to the portal and official documentation.

### Foundry building blocks

| Term | Plain-language meaning | Use in this scenario |
| --- | --- | --- |
| [Microsoft Foundry account](https://learn.microsoft.com/azure/foundry/what-is-foundry) | The parent Azure resource that groups projects and model deployments. | Terraform creates one account. |
| [Foundry project](https://learn.microsoft.com/azure/foundry/how-to/create-projects) | A workspace that groups agents, connections, and conversations. Agents in one project share its connected stores, while data is isolated from other projects. | Terraform creates one project in the account. |
| [Model deployment](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/deployment-types) | A selected model and version made callable through an API under a deployment name, processing mode (SKU), and capacity. It isn't an agent. | Terraform creates the entries specified by `model_deployments`. |
| [Foundry Agent Service](https://learn.microsoft.com/azure/foundry/agents/overview) | A Microsoft service that manages agent definitions, execution, and conversation state. It isn't a large language model (LLM) by itself; it runs agents that combine models and tools. | It runs the prompt agent described below. |
| [Prompt agent](https://learn.microsoft.com/azure/foundry/agents/quickstarts/prompt-agent) | An agent defined as configuration: instructions, a model, and tools. Foundry runs it, unlike a hosted agent for which the developer supplies application code or a container. | Script `07` creates a prompt agent version. |

### Basic setup and Standard setup

A **setup** is the Agent Service environment configuration that determines where
the service stores state. State includes uploaded files, retrieval vector stores,
conversations, and agent definitions. See
[Set up your agent environment](https://learn.microsoft.com/azure/foundry/agents/environment-setup#choose-your-setup)
for the official comparison.

| Setup | Where agent state is stored | What the customer manages | Used here |
| --- | --- | --- | --- |
| [Basic setup](https://learn.microsoft.com/azure/foundry/agents/environment-setup#choose-your-setup) | Built-in, Microsoft-managed platform stores | Foundry account, project, models, and related configuration | No |
| [Standard setup](https://learn.microsoft.com/azure/foundry/agents/concepts/standard-agent-setup) | Storage, Search, and Cosmos DB resources dedicated to the customer in the customer's Azure subscription | The Basic resources plus the three data services, connections, and permissions | Yes |
| [Standard setup with Bring Your Own (BYO) virtual network](https://learn.microsoft.com/azure/foundry/agents/how-to/virtual-networks) | The same customer-managed resources as Standard setup, with traffic restricted to the customer's virtual network | Private endpoints, DNS, network policy, and related resources as well | No |

Therefore, **Standard describes the data-storage setup, not a model, model SKU,
agent type, or inference-performance tier**. This scenario runs a prompt agent on
Standard setup with public endpoints.

### Resource connections and authentication

| Term | Meaning in this README |
| --- | --- |
| [Managed identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) | A Microsoft Entra identity assigned to an Azure resource. Azure manages its credentials, so the resource can obtain access tokens without storing passwords or resource keys in code or Terraform state. This scenario primarily uses the Foundry project identity and Search identity. |
| [Keyless authentication](https://learn.microsoft.com/azure/foundry/concepts/authentication-authorization-foundry) | Authentication with short-lived access tokens issued by Microsoft Entra ID instead of Storage or Search resource keys, API keys, or connection strings. It doesn't mean that authentication is absent. |
| [Azure RBAC](https://learn.microsoft.com/azure/role-based-access-control/overview) | Authorization through role assignments that answer "which identity can perform which actions at which scope?" An identity can obtain a token but still receive `403` if it lacks the required role on the target resource. |
| [Project connection](https://learn.microsoft.com/azure/foundry/how-to/connections-add) | A configuration object that tells a Foundry project how to refer to an external resource. It records details such as the target API URL (endpoint), resource ID, and authentication method; it doesn't copy the Storage or Search data. |
| [Capability host](https://learn.microsoft.com/azure/foundry/agents/concepts/capability-hosts) | An ARM configuration object under a Foundry account or project that tells Agent Service which connections to use. It isn't an application host or server. The account capability host enables Agent Service for the account; the project capability host selects the Storage, Search, and Cosmos DB connections for that project. |
| [Access-token audience](https://learn.microsoft.com/entra/identity-platform/access-tokens) | The identifier of the API that should accept a token. ARM, Storage, Search, and Foundry are separate APIs, so the same identity obtains a token for each audience. A scope such as `https://search.azure.com/.default` asks Microsoft Entra ID for a token intended for that API. |

#### Why capability hosts exist

Project connections and capability hosts work together, but they have different
jobs. In plain terms, **a connection is an address-book entry for a resource; a
capability host is an assignment table that tells Agent Service which entry to
use for each purpose**.

A Foundry project can contain multiple connections to services such as Search
and Storage. The presence of a connection alone doesn't tell Agent Service which
one should store files or which one should store conversations. A capability
host assigns those purposes to connections so that every agent in the project
uses the same stores consistently. Its reason for existing is to keep reusable
connection details separate from Agent Service-specific storage configuration.

| Configuration element | What it does | What it doesn't do |
| --- | --- | --- |
| Project connection | Registers the target resource's endpoint, resource ID, and authentication method | Doesn't select its purpose in Agent Service |
| Account capability host | Enables Agent Service for the Foundry account | Doesn't automatically select stores for a project |
| Project capability host | Assigns a Storage connection to `storageConnections`, Search to `vectorStoreConnections`, and Cosmos DB to `threadStorageConnections` | Doesn't store data itself or proxy requests |
| Managed identity and RBAC | Provide the identity and permissions that can actually use the assigned resource | Don't select which store Agent Service uses |

With Basic setup, no capability hosts are created and Agent Service uses the
Microsoft-managed default stores. Standard setup requires capability hosts at
both account and project scopes. At runtime, Agent Service reads the project
capability host, resolves the connection for each purpose, and uses managed
identity and RBAC to access the target Storage, Search, or Cosmos DB service.

A capability host isn't a database, compute host, or network gateway. It holds
no agent data and grants no permissions. Only one capability host can be active
at each account or project scope; changing the selected stores requires deleting
it and recreating it with the new configuration.

### Knowledge retrieval

| Term | Meaning in this README |
| --- | --- |
| [Foundry IQ](https://learn.microsoft.com/azure/foundry/agents/concepts/what-is-foundry-iq) | A knowledge layer that lets agents search private data. It brings together knowledge sources and knowledge bases backed by Azure AI Search. |
| [Knowledge source](https://learn.microsoft.com/azure/search/agentic-knowledge-source-overview) | An object that describes where searchable data comes from and how to ingest it. Here it points to the CSV in Blob Storage, and the service generates a pipeline that splits long content into searchable passages (chunking), creates embeddings, and builds a search index. |
| [Embeddings and vector search](https://learn.microsoft.com/azure/search/vector-search-overview) | An embedding represents the meaning of text as numbers. Vector search uses the distance between those numbers to find passages whose meaning is close to a question. |
| [Knowledge base](https://learn.microsoft.com/azure/search/agentic-retrieval-how-to-create-knowledge-base) | A top-level object that combines one or more knowledge sources and search settings behind an API that retrieves relevant passages. It isn't the index itself or an agent. |
| [Agentic retrieval](https://learn.microsoft.com/azure/search/agentic-retrieval-overview) | Retrieval that can decompose a question into searches, rerank results, and return the evidence as one response. The `minimal` setting in this scenario doesn't use LLM query planning. |
| [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) | An open protocol through which AI applications call external tools and data sources in a common format. The RemoteTool connection exposes the Search knowledge base MCP endpoint to the prompt agent. |
| [Grounded answer and citation](https://learn.microsoft.com/azure/foundry/agents/concepts/what-is-foundry-iq#capabilities) | A grounded answer is generated from retrieved evidence. A citation identifies evidence that can be traced back to the source, distinguishing the result from an answer based only on model training. |

In one sentence, the scenario **stores a CSV in Blob Storage, lets a knowledge
source build a search index, retrieves relevant passages through a knowledge base,
passes them to a prompt agent over MCP, and generates an evidence-based answer**.

## Scenario purpose

### What "Standard Agent" means in this scenario

The Terraform input `deploy_standard_agent` and some descriptions use
"Standard Agent" as shorthand for **an agent running on Standard setup
infrastructure**. It isn't an official agent type. This README keeps two choices
separate:

| Choice | Selection in this scenario | What it determines |
| --- | --- | --- |
| Agent Service setup | Standard setup with public networking | Where agent state is stored and how the environment is networked |
| Agent type | Prompt agent | Whether the agent is managed as instructions, model, and tool configuration |

Standard setup connects a Foundry project to customer-dedicated resources in the
customer's subscription. Each resource has a distinct responsibility:

* Azure Storage stores files and uploads.
* Azure AI Search stores vector stores and retrieval indexes.
* Azure Cosmos DB stores conversations, responses, and agent metadata.

Account and project capability hosts tell Agent Service which connected
resources to use. This scenario uses keyless Microsoft Entra authentication but
keeps public network endpoints enabled. It therefore removes resource keys from
the authentication path without providing private-network isolation.

### What this scenario delivers

The Terraform phase creates a Foundry account and project, model deployments,
customer-owned Storage, Search, and Cosmos DB services, project connections,
capability hosts, managed identities, and RBAC. The post-deployment phase then:

1. Uploads a fictional CSV to Blob Storage.
2. Creates a Foundry IQ Blob knowledge source and its generated Search pipeline.
3. Creates and directly tests a knowledge base.
4. Connects the knowledge base to a prompt agent over MCP.
5. Sends a question through the Responses API and verifies grounded output.

The completed scenario is a reproducible learning environment for a keyless,
retrieval-grounded prompt agent. It is not a production application, hosted
agent, user interface, or private-network reference architecture.

### What you learn

After completing the workflow, you should be able to:

* Distinguish ARM resources from service data-plane objects and know why their
    lifecycles use different tools.
* Identify which identity, RBAC role, OAuth audience, and endpoint are used at
    each step.
* Explain how capability hosts connect customer-owned state services to a
    Foundry project.
* Trace Blob ingestion through chunking, embedding, indexing, knowledge-base
    retrieval, MCP tool invocation, and final answer generation.
* Isolate ingestion and retrieval failures before adding the agent layer.
* Decide which parts belong in Terraform state and which require a Search or
    Foundry data-plane client until provider support covers those objects.

## Architecture

The following views separate API planes from execution flows. The first diagram
shows **where an object lives and which client manages it**. The sequence
diagrams then show when those surfaces communicate during deployment and during
a user request.

> [!IMPORTANT]
> In this README, **ARM control plane** means Azure Resource Manager operations
> for resources in a subscription. It is different from the product feature
> named **Microsoft Foundry Control Plane**, which provides fleet-wide
> governance, inventory, and observability and is outside this scenario.

### ARM control plane and service data planes

The following views answer: **is an object an Azure resource or a runtime object
inside a service, and which tool manages it in this scenario?** Instead of
placing every object in one large boundary, each Azure resource has its own view.
In each view, the control plane configures the resource through Azure Resource
Manager (ARM), while the data plane handles data or objects created and used as
the agent runs. Here, an object is one unit of configuration or data that an API
can create, retrieve, or delete.

#### Microsoft Foundry account and project

```mermaid
flowchart LR
    subgraph Foundry["Microsoft Foundry account and project"]
        direction TB
        FoundryArm["Control plane<br/>account, project, model deployments<br/>connections, capability hosts"]
        FoundryData["Data plane<br/>prompt agent versions<br/>conversations, responses"]
        FoundryArm -.->|"project runtime boundary"| FoundryData
    end

    Terraform["Terraform"] -->|"ARM API"| FoundryArm
    ArmScripts["scripts 06 and 09"] -->|"ARM REST"| FoundryArm
    FoundryScripts["scripts 07 through 09"] -->|"Foundry project API"| FoundryData
```

#### Azure Storage

```mermaid
flowchart LR
    subgraph Storage["Azure Storage"]
        direction TB
        StorageArm["Control plane<br/>Storage account<br/>local authentication disabled"]
        StorageData["Data plane<br/>private container<br/>restaurant review CSV"]
        StorageArm -.->|"data in the account"| StorageData
    end

    Terraform["Terraform"] -->|"ARM API"| StorageArm
    BlobScripts["scripts 01 and 09"] -->|"Blob REST API"| StorageData
    SearchIdentity["Search managed identity"] -->|"read CSV during ingestion"| StorageData
```

#### Azure AI Search

```mermaid
flowchart LR
    subgraph Search["Azure AI Search"]
        direction TB
        SearchArm["Control plane<br/>Search service<br/>managed identity and authentication settings"]
        SearchData["Data plane<br/>knowledge source and generated pipeline<br/>knowledge base, retrieve, MCP endpoint"]
        SearchArm -.->|"objects in the service"| SearchData
    end

    Terraform["Terraform"] -->|"ARM API"| SearchArm
    SearchScripts["scripts 02 through 05 and 09"] -->|"Search REST API"| SearchData
    PromptAgent["Prompt agent"] -->|"retrieve over MCP"| SearchData
    SearchData -->|"generate embeddings during ingestion"| EmbeddingModel["Foundry model deployment"]
```

#### Azure Cosmos DB

```mermaid
flowchart LR
    subgraph Cosmos["Azure Cosmos DB"]
        direction TB
        CosmosArm["Control plane<br/>Cosmos DB account<br/>project connection"]
        CosmosData["Data plane<br/>enterprise_memory<br/>conversations and agent metadata"]
        CosmosArm -.->|"managed state in the account"| CosmosData
    end

    Terraform["Terraform"] -->|"ARM API"| CosmosArm
    AgentService["Foundry Agent Service"] -->|"read and write at runtime"| CosmosData
```

The boundary is determined by the API, not by whether an operation happens
before or after `terraform apply`. Script `06`, for example, runs after Search
data-plane setup but creates a project connection through ARM, so it is a
control-plane operation. Knowledge sources and knowledge bases are top-level
objects in the Search service data plane, not ARM child resources. Prompt agent
versions, conversations, and responses are Foundry project data-plane objects.

| API surface | Endpoint or token audience | Objects used here | Management in this scenario |
| ------------- | ---------------------------- | ------------------- | ----------------------------- |
| ARM control plane | `management.azure.com` | Foundry account/project, model deployments, connections, capability hosts, data-service accounts, RBAC | Terraform; script `06` creates and script `09` deletes the RemoteTool connection |
| Storage data plane | `https://storage.azure.com/.default` | Private container and review CSV | Scripts `01` and `09` |
| Search data plane | `https://search.azure.com/.default` | Knowledge source, generated data source/skillset/index/indexer, knowledge base, retrieval | Scripts `02` through `05` and `09` |
| Foundry project data plane | `https://ai.azure.com/.default` | Prompt agent versions, conversations, Responses API calls | Scripts `07` through `09` |
| Model data plane | Foundry OpenAI endpoint | Embeddings and final response generation | Search managed identity and Agent Service at runtime |
| Cosmos DB data plane | Project capability-host connection | `enterprise_memory` and Agent Service state | Agent Service; the scripts do not call Cosmos DB directly |

Terraform is a natural fit for ARM resource lifecycle and RBAC. In this
implementation, the Search and Foundry data-plane objects aren't stored in
Terraform state, so the numbered scripts manage them with service REST APIs.
Script `09` cleans up the persistent named objects listed in the cleanup section;
it doesn't track or delete conversations created by script `08`. `terraform
destroy` handles the ARM resources.

### Why Terraform and scripts are separate

The split is an implementation boundary, not a claim that Terraform can never
manage a data plane. Terraform can manage a data-plane object when a provider
implements CRUD operations, import, and state for that object. In this scenario:

* Terraform and `azapi_resource` manage objects with ARM resource IDs.
* A Search knowledge source or knowledge base is addressed by name at the Search
    endpoint. It isn't a child resource under the Search service ARM ID.
* The generated data source, skillset, index, and indexer are owned by the Blob
    knowledge source's fixed template. They shouldn't be edited or managed as
    independent Terraform resources.
* Prompt agent versions and conversations live under the Foundry project data
    plane. Script `07` uses `POST`, so rerunning it creates another agent version.

The current provider set doesn't put these Search and Foundry objects in state.
Wrapping their REST calls in `local-exec` would run them during Terraform, but it
wouldn't provide declarative diff, import, or lifecycle tracking. The scripts
therefore use create-or-update `PUT` operations where the API supports them and
provide an explicit cleanup step. Script `06` is the deliberate exception: its
RemoteTool connection is an ARM object, but this implementation creates it after
the MCP endpoint exists and keeps its lifecycle with the post-deployment workflow.

### Deployment flow

This view answers: **in what order is the environment built and verified?**

```mermaid
sequenceDiagram
    autonumber
    actor Operator
    participant CLI as Azure CLI
    participant TF as Terraform
    participant ARM as ARM control plane
    participant Storage as Storage data plane
    participant Search as Search data plane
    participant Models as Model data plane
    participant Foundry as Foundry project data plane

    Operator->>CLI: Confirm subscription and operator object ID
    Operator->>TF: init, plan, apply -parallelism=1
    TF->>ARM: Create Foundry, models, Search, Storage, and Cosmos DB
    TF->>ARM: Assign RBAC and wait for propagation
    TF->>ARM: Create project connections and capability hosts
    Operator->>CLI: Validate outputs and four token audiences (script 00)
    Operator->>Storage: Upload review CSV (script 01)
    Operator->>Search: Create Blob knowledge source (script 02)
    Search->>Storage: Read CSV with the Search managed identity
    Search->>Models: Invoke the embedding model with managed identity
    Operator->>Search: Wait for ingestion (script 03)
    Operator->>Search: Create knowledge base and test retrieval (scripts 04-05)
    Operator->>ARM: Create RemoteTool project connection (script 06)
    Operator->>Foundry: Create prompt agent version (script 07)
    Operator->>Foundry: Run grounded Q&A (script 08)
```

### Q&A runtime flow

This view answers: **which services communicate after a user asks a question?**

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Agent as Foundry data plane prompt agent
    participant Cosmos as Cosmos DB data plane state
    participant Tool as MCP RemoteTool connection
    participant KB as Search data plane knowledge base
    participant Index as Generated Search index
    participant Model as Model data plane gpt-5.4-mini

    User->>Agent: Ask a question through the Responses API
    Agent->>Cosmos: Persist conversation and thread state
    Agent->>Tool: Call knowledge_base_retrieve over MCP
    Tool->>KB: Submit the retrieval request
    KB->>Index: Run agentic retrieval
    Index-->>KB: Return relevant chunks and references
    KB-->>Tool: Return grounded evidence
    Tool-->>Agent: Return MCP tool result
    Agent->>Model: Generate an answer from the evidence
    Model-->>Agent: Return the grounded answer
    Agent->>Cosmos: Update conversation state
    Agent-->>User: Return answer and citations
```

Blob Storage and the embedding deployment participate in ingestion, as shown in
the deployment flow. They are not called for each Q&A request. Terraform is also
absent from the runtime path.

## Prerequisites and constraints

### Required access and tools

* Azure subscription
* Azure CLI 2.50 or later, signed in to the target subscription
* Terraform 1.11 or later
* POSIX-compatible shell, `curl`, and `jq`
* A target region that supports Foundry Agent Service and Azure AI Search
    agentic retrieval
* Quota and regional availability for every configured model deployment
* Permission to create role assignments on the deployed data services

Follow the shared [Azure authentication](../../../docs/tips/provider-authentication.md),
[Terraform workflow](../../../docs/tips/terraform-workflow.md), and optional
[Azure Blob Storage backend](../../../docs/tips/azure-blob-backend.md) guidance.
Set `SCENARIO=azure_microsoft_foundry` when using the repository Makefile.

### Service and design constraints

| Area | Boundary in this scenario |
| --- | --- |
| Setup mode | Standard setup with public endpoints and customer-owned Storage, Search, and Cosmos DB. It isn't the BYO virtual-network variant. |
| Project boundary | One account and one project are created. Agents in the project share its connected state services; this scenario doesn't test multi-project isolation or capacity. |
| Cosmos DB | The scenario creates a provisioned-throughput account. Standard setup requires capacity for at least 3000 RU/s total throughput; capability-host provisioning can fail when capacity is insufficient. |
| Capability hosts | Foundry doesn't support updating a capability host after it is set. Changing its connected state services can require replacement or project recreation. |
| Network security | Microsoft Entra authentication removes keys but doesn't isolate traffic. No private endpoints, private DNS, firewall policy, or egress controls are created. |
| Data authorization | The sample doesn't configure document-level ACL synchronization or end-user token passthrough. Any authorized caller of this agent uses the same fictional corpus. |
| API stability | Search calls use `2026-05-01-preview`, and the RemoteTool connection uses `2025-10-01-preview`. Preview behavior can change and has no SLA. |
| Data processing | Default model deployments use `GlobalStandard`, which can process requests across Azure-managed regions. Don't infer single-region model processing from `location = "japaneast"`. |
| Production readiness | No customer-managed Key Vault/CMK, private networking, application UI, observability stack, evaluation suite, or application-specific responsible AI testing is included. |
| Cost | Search, Cosmos DB, Storage, model tokens, and agentic retrieval can incur charges. Review quota, throughput, free allowances, and current pricing before deployment. |

## Configuration

### Model deployments

By default, the scenario creates the following model deployments in the
Microsoft Foundry account:

| Deployment and model         | Version      | SKU              | Capacity |
|------------------------------|--------------|------------------|---------:|
| `gpt-5.6-luna`               | `2026-07-09` | `GlobalStandard` |     1000 |
| `gpt-5.6-terra`              | `2026-07-09` | `GlobalStandard` |     1000 |
| `gpt-5.6-sol`                | `2026-07-09` | `GlobalStandard` |     1000 |
| `gpt-5.4-mini`               | `2026-03-17` | `GlobalStandard` |     1000 |
| `text-embedding-3-large`     | `1`          | `GlobalStandard` |     3000 |
| `text-embedding-3-small`     | `1`          | `GlobalStandard` |     3000 |

Review and override `model_deployments` before applying to match the models,
versions, capacity, and quota available in the target subscription and region.
Set it to an empty list to create the account and project without model
deployments:

```hcl
model_deployments = []
```

### Standard setup resources

The Terraform input is named `deploy_standard_agent`, but it enables Standard
setup infrastructure; it doesn't select an agent kind. The input defaults to
`false`. When disabled, the scenario creates only the Foundry account, project,
and model deployments. Enable the customer-owned state services and capability
hosts with the following values:

```hcl
deploy_standard_agent = true
azure_ai_search_sku   = "standard"
```

The checked-in `terraform.tfvars` enables this configuration. Terraform creates
the following resources together:

* Azure AI Search using `standard` or a higher supported SKU
* Standard/ZRS Storage account without a Terraform-managed container
* Azure Cosmos DB for agent threads using Session consistency
* Project-scoped AAD connections for Search, Storage, and Cosmos DB
* Account and project capability hosts using the stable `2025-06-01` API

Standard setup alone doesn't create the restaurant knowledge source, knowledge
base, MCP connection, or prompt agent. This scenario reuses the same Storage and
Search services for that separate Foundry IQ pipeline, which the numbered
scripts build after the environment is ready.

The data services use public network endpoints. AAD-only authentication removes
resource keys from the authentication path, but it does not provide network
isolation. Terraform does not create private endpoints, private DNS zones, Search
data-plane objects, or agent versions. The numbered scripts create the Blob
container, Search-managed ingestion resources, Foundry IQ objects, RemoteTool
connection, and prompt agent after Terraform has finished.

### Authentication and RBAC

Local authentication is disabled for the Foundry account and all standard agent
data services. Terraform creates the following assignments when
`deploy_standard_agent` is enabled:

| Scope                  | Role                                | Assignee                 | Purpose                              |
|------------------------|-------------------------------------|--------------------------|--------------------------------------|
| Storage account        | Storage Blob Data Contributor       | Foundry project identity | Read and write agent files           |
| Azure AI Search        | Search Index Data Contributor       | Foundry project identity | Read and write index data            |
| Azure AI Search        | Search Service Contributor          | Foundry project identity | Manage Search resources              |
| Azure AI Search        | Search Index Data Reader            | Foundry project identity | Retrieve knowledge through MCP       |
| Foundry account        | Foundry User                        | Foundry project identity | Access Foundry models and agents     |
| Cosmos DB account      | Cosmos DB Operator                  | Foundry project identity | Manage account metadata              |
| `enterprise_memory` DB | Cosmos DB Built-in Data Contributor | Foundry project identity | Read and write thread data           |
| Storage account        | Storage Blob Data Reader            | Search identity          | Ingest the review CSV                |
| Foundry account        | Cognitive Services User             | Search identity          | Generate embeddings during ingestion |
| Storage account        | Storage Blob Data Contributor       | Operator                 | Upload and remove the review CSV     |
| Azure AI Search        | Search Service Contributor          | Operator                 | Manage knowledge objects             |
| Azure AI Search        | Search Index Data Contributor       | Operator                 | Manage generated index data          |
| Azure AI Search        | Search Index Data Reader            | Operator                 | Run direct retrieval tests           |
| Foundry account        | Foundry Project Manager             | Operator                 | Create the connection and agent      |

`operator_principal_id` defaults to the object ID of the identity running
Terraform when the input is `null`. The checked-in `terraform.tfvars` explicitly
sets an object ID, so it takes precedence over that fallback. The deployment
steps below resolve the current Azure CLI principal and pass it with `-var`,
which has higher precedence than the checked-in value. Use the object ID of the
principal that runs the numbered scripts if Terraform and the scripts run as
different identities. Foundry roles are assigned by role definition ID to avoid
failures while Azure AI role names are being renamed.

Terraform waits 60 seconds after the control-plane role assignments. It then
creates the account capability host and project capability host with 60-minute
create timeouts. The project host creates the `enterprise_memory` database, so
its Cosmos DB data-plane role assignment is applied last.

The Terraform identity needs `Microsoft.Authorization/roleAssignments/write` at
the target scopes. Contributor alone cannot create role assignments. Use Owner,
User Access Administrator combined with the required resource permissions, or a
custom role that grants the required actions.

### Data and API design

The mock corpus is [data/restaurant_reviews.csv](data/restaurant_reviews.csv).
It contains 30 English reviews for 10 explicitly fictional restaurants. Each row
repeats the restaurant name, cuisine, address, coordinates, hours, dietary
options, overview, rating, and review in a self-contained `search_text` field.

> [!IMPORTANT]
> The selected `azureBlob` knowledge source creates its data source, skillset,
> vectorized index, and indexer from a service-managed fixed template. A CSV is
> treated as Blob content and chunked by that template. Individual CSV columns
> are not guaranteed to become typed or filterable Search fields. Use an
> explicitly managed index and a `delimitedText` indexer instead when row-level
> filters or stable column mappings are required.

The two ID columns are source-level business identifiers, not Azure AI Search
document keys:

| Column          | Uniqueness               | Purpose                              | Example    |
|-----------------|--------------------------|--------------------------------------|------------|
| `review_id`     | One value per review     | Trace a review in the source dataset | `rev-001`  |
| `restaurant_id` | One value per restaurant | Group reviews for a restaurant       | `rest-001` |

Keep these stable, human-readable IDs for this fixture and never reuse an ID for
a different record. Adding a UUID column would not improve Search identity in
the current pipeline: the service-managed Blob knowledge source treats the CSV
as Blob content, chunks it, and generates the index keys used for retrieval.
The CSV IDs are therefore not guaranteed to become typed, filterable, or stable
Search key fields. Removing them would only reduce source traceability.

For production data without a durable source ID, generate an ID once when the
record is created and persist it; do not generate a new random UUID on each
ingestion. When multiple sources share a namespace, use a source-qualified,
deterministic ID or a persisted UUID. If row-level filtering, updates, or key
stability become requirements, replace the fixed Blob pipeline with an
explicitly managed index and a `delimitedText` indexer, then define the parent
record key and any derived chunk keys as part of that schema.

The workflow uses these model responsibilities:

* `text-embedding-3-large` vectorizes content during Blob ingestion
* Foundry IQ uses `minimal` reasoning with `extractiveData` output
* `gpt-5.4-mini` generates the final grounded answer in the prompt agent

The Search data-plane calls use the `2026-05-01-preview` API. Search resources
and direct retrieval use OData-style paths such as
`knowledgebases('restaurant-reviews-kb')/retrieve`. The MCP endpoint uses the
different slash-style path
`/knowledgebases/restaurant-reviews-kb/mcp?api-version=2026-05-01-preview`.
The RemoteTool connection uses `2025-10-01-preview`, and the agent uses `v1`.

> [!WARNING]
> Preview APIs have no service-level agreement and are not recommended for
> production workloads. Review Azure preview terms, regional availability, data
> boundaries, model availability, and API changes before production use.

## Deployment

Complete these sections in order. Each verification step narrows failures to the
layer built immediately before it.

### 1. Select the subscription and operator principal

Sign in and select the subscription that Terraform and the scripts will use:

```bash
az login
az account set --subscription "<subscription-name-or-id>"
az account show \
    --query "{subscriptionName:name, subscriptionId:id, tenantId:tenantId, principalType:user.type, principalName:user.name}" \
    --output table
```

For an interactive user login, resolve the signed-in user's Microsoft Entra
object ID:

```bash
OPERATOR_PRINCIPAL_ID=$(az ad signed-in-user show --query id --output tsv)
printf 'operator_principal_id=%s\n' "$OPERATOR_PRINCIPAL_ID"
```

For a service principal login, `user.name` is its application (client) ID.
Resolve that value to the service principal object ID:

```bash
AZURE_CLIENT_ID=$(az account show --query user.name --output tsv)
OPERATOR_PRINCIPAL_ID=$(az ad sp show \
    --id "$AZURE_CLIENT_ID" \
    --query id \
    --output tsv)
printf 'operator_principal_id=%s\n' "$OPERATOR_PRINCIPAL_ID"
```

`operator_principal_id` requires the **object ID**. Do not pass the application
(client) ID, subscription ID, or tenant ID. The directory lookup also requires
permission to read the principal. In a restricted CI tenant, store the known
service principal object ID as a protected CI variable instead.

### 2. Review and plan the configuration

From this scenario directory, review `terraform.tfvars` and the model deployment
table above. Confirm that the target region has the required model versions,
capacity, and quota, then initialize, validate, and review the plan:

```bash
terraform init
terraform validate
terraform plan -var="operator_principal_id=${OPERATOR_PRINCIPAL_ID}"
```

The command-line `-var` deliberately overrides the object ID checked into
`terraform.tfvars`. The plan should include the operator role assignments when
`deploy_standard_agent` is `true`.

### 3. Deploy the Terraform-managed infrastructure

Model deployments must be created sequentially. Apply with Terraform
parallelism set to one, then inspect the outputs used by the scripts:

```bash
terraform apply -parallelism=1 \
    -var="operator_principal_id=${OPERATOR_PRINCIPAL_ID}"
terraform output
```

### 4. Build and verify the knowledge layer

The scripts resolve files relative to their own location, so the caller's
working directory does not matter. Set `SCENARIO_DIR` to the absolute path of
this scenario. Run validation first, then upload and ingest the CSV, create the
knowledge base, and test direct retrieval:

```bash
SCENARIO_DIR="/path/to/template-terraform/infra/scenarios/azure_microsoft_foundry"

"${SCENARIO_DIR}/scripts/00_validate_prerequisites.sh"
"${SCENARIO_DIR}/scripts/01_upload_restaurant_reviews.sh"
"${SCENARIO_DIR}/scripts/02_create_knowledge_source.sh"
"${SCENARIO_DIR}/scripts/03_wait_for_ingestion.sh"
"${SCENARIO_DIR}/scripts/04_create_knowledge_base.sh"
"${SCENARIO_DIR}/scripts/05_retrieve_knowledge_base.sh" \
    "Which fictional restaurants offer vegan options, and what did reviewers say?"
```

Step `05` is the knowledge-layer verification gate. Continue only after it
returns relevant grounding references.

### 5. Create and test the prompt agent

Create the RemoteTool connection and prompt agent, then run an end-to-end Q&A
request:

```bash
"${SCENARIO_DIR}/scripts/06_create_project_connection.sh"
"${SCENARIO_DIR}/scripts/07_create_agent.sh"
"${SCENARIO_DIR}/scripts/08_ask_agent.sh" \
    "Which fictional restaurant is a strong choice for a vegan dinner, and why?"
```

Step `08` is the runtime verification gate. It should report at least one MCP
event and return an answer grounded in the restaurant dataset.

### Script reference

| Script                                    | Operation                                                     |
|-------------------------------------------|---------------------------------------------------------------|
| `00_validate_prerequisites.sh`            | Validate tools, outputs, deployments, login, and token scopes |
| `01_upload_restaurant_reviews.sh`         | Create a private container and upload the CSV with Blob REST  |
| `02_create_knowledge_source.sh`           | Create the keyless Blob knowledge source and generated index  |
| `03_wait_for_ingestion.sh`                | Wait for the current ingestion run and fail on item errors    |
| `04_create_knowledge_base.sh`             | Create the minimal extractive Foundry IQ knowledge base       |
| `05_retrieve_knowledge_base.sh`           | Test direct retrieval and display grounding references        |
| `06_create_project_connection.sh`         | Create the project-managed-identity RemoteTool connection     |
| `07_create_agent.sh`                      | Create a new version of the MCP-enabled prompt agent          |
| `08_ask_agent.sh`                         | Create a conversation and force a knowledge-base tool call    |
| `09_cleanup.sh`                           | Delete only resources created by the numbered scripts         |

Direct retrieval in step `05` separates Search ingestion problems from agent
or MCP problems. Step `08` prints the answer, conversation ID, and count of MCP
events. Set `VERBOSE_OUTPUT=true` for the complete JSON response.

## Operations

### Configuration overrides

| Environment variable             | Default                          | Purpose                              |
|----------------------------------|----------------------------------|--------------------------------------|
| `RESTAURANT_DATA_FILE`           | `data/restaurant_reviews.csv`    | Source CSV path                      |
| `CONTAINER_NAME`                 | `restaurant-reviews`             | Private Blob container               |
| `BLOB_NAME`                      | `restaurant_reviews.csv`         | Uploaded Blob name                   |
| `KNOWLEDGE_SOURCE_NAME`          | `restaurant-reviews-ks`          | Search knowledge source              |
| `KNOWLEDGE_BASE_NAME`            | `restaurant-reviews-kb`          | Search knowledge base                |
| `PROJECT_CONNECTION_NAME`        | `restaurant-reviews-kb-mcp`      | Foundry RemoteTool connection        |
| `AGENT_NAME`                     | `restaurant-qa-agent`            | Foundry prompt agent                 |
| `AGENT_MODEL`                    | `gpt-5.4-mini`                   | Agent model deployment               |
| `EMBEDDING_DEPLOYMENT`           | `text-embedding-3-large`         | Ingestion embedding deployment       |
| `EMBEDDING_MODEL`                | `text-embedding-3-large`         | Ingestion embedding model name       |
| `INGESTION_TIMEOUT_SECONDS`      | `900`                            | Maximum ingestion wait               |
| `POLL_INTERVAL_SECONDS`          | `10`                             | Ingestion polling interval           |
| `VERBOSE_OUTPUT`                 | `false`                          | Print complete REST response bodies  |

Endpoint and resource variables can also override Terraform outputs for advanced
testing. The scripts never write bearer tokens, API keys, or connection secrets
to disk or standard output.

### Rerun and cleanup behavior

The Blob upload overwrites the named Blob. Knowledge source, knowledge base, and
project connection steps use create-or-update `PUT` operations and are safe to
rerun with the same names. Agent creation uses `POST`; each rerun creates another
version of the named agent. Every agent query creates a new conversation.

Cleanup is intentionally separate from Terraform and requires an exact
confirmation value. It deletes the agent, RemoteTool connection, knowledge base,
knowledge source and its generated Search objects, Blob, and container. It does
not change Terraform-managed infrastructure:

```bash
CONFIRM_CLEANUP=delete-foundry-iq-resources \
    "${SCENARIO_DIR}/scripts/09_cleanup.sh"
```

### Destroy and purge

Deleting a Microsoft Foundry account normally soft-deletes it. Without a purge,
the account name cannot be reused for 48 hours. This scenario registers a
Terraform destroy-time hook that deletes the model deployments, project, and
account, then runs `az cognitiveservices account purge` before deleting the
resource group.

> [!WARNING]
> Purging is irreversible. All data and keys associated with the account are
> permanently deleted. The identity running Terraform must have the
> `Microsoft.CognitiveServices/locations/resourceGroups/deletedAccounts/delete`
> permission. A resource-group-scoped `Contributor` assignment is not
> sufficient; use a suitable role such as `Cognitive Services Contributor` or
> `Contributor` at subscription scope. See
> [Recover or purge deleted Microsoft Foundry resources](https://learn.microsoft.com/azure/ai-services/recover-purge-resources).

The purge action must exist in Terraform state before destroy. After adding or
upgrading to this configuration, run `terraform apply` once before the first
`terraform destroy`. If the purge fails because permission is missing, grant the
permission and rerun `terraform destroy`; the account remains soft-deleted until
the purge succeeds.

Model deployments require sequential Terraform operations. The standard
Makefile deploy and destroy commands do not include the `-parallelism=1`
override. Resolve `OPERATOR_PRINCIPAL_ID` as described in the deployment section,
then run these commands directly from the scenario directory:

```bash
# Apply once to register the destroy-time purge action
terraform apply -parallelism=1 \
    -var="operator_principal_id=${OPERATOR_PRINCIPAL_ID}"

# Confirm the output
terraform output

# Destroy the deployment and permanently purge the Foundry account
terraform destroy -parallelism=1 \
    -var="operator_principal_id=${OPERATOR_PRINCIPAL_ID}"
```

## Troubleshooting

* For Search `401` or `403`, confirm the operator has Search Service Contributor,
    Search Index Data Contributor, and Search Index Data Reader, then allow time
    for role assignments to propagate.
* For Blob `403`, confirm the operator has Storage Blob Data Contributor and the
    Search identity has Storage Blob Data Reader on the storage account.
* For embedding errors, confirm the Search identity has Cognitive Services User
    on the Foundry account and `text-embedding-3-large` is deployed.
* For agent or connection `403`, confirm the operator has Foundry Project Manager
    and the project identity has Foundry User.
* For ingestion failure, inspect the errors printed by step `03`. Verify the Blob
    is UTF-8 CSV and rerun steps `01` through `03` after correcting the source.
* For an MCP `400` or `404`, confirm the knowledge base name and preserve the
    slash-style MCP endpoint with `2026-05-01-preview`.
* Semantic ranker and agentic retrieval begin on their default monthly free
    allowances. Requests return billing errors after an allowance is exhausted
    unless the corresponding Standard pay-as-you-go plan is enabled separately.

## Migration from standalone inputs

The `deploy_azure_ai_search` and `deploy_blob_storage` inputs have been removed.
Use `deploy_standard_agent` to deploy all three data services as one supported
configuration. The Search `free` and `basic` SKUs are no longer accepted.

> [!WARNING]
> Migrating an existing deployment can replace the LRS Storage account with a
> ZRS account and remove the previously managed `default` container. Review the
> plan and preserve any required data before applying. Switching connections to
> AAD removes active key references from configuration, but keys recorded in
> earlier remote state versions are not deleted automatically. Retain, rotate,
> or remove state history according to your backend security policy.

## References

### Concepts and architecture

* [What is Microsoft Foundry?](https://learn.microsoft.com/azure/foundry/what-is-foundry)
* [What is Microsoft Foundry Agent Service?](https://learn.microsoft.com/azure/foundry/agents/overview)
* [Quickstart: Create a prompt agent](https://learn.microsoft.com/azure/foundry/agents/quickstarts/prompt-agent)
* [Set up your agent environment: Basic and Standard setup](https://learn.microsoft.com/azure/foundry/agents/environment-setup)
* [Set up Standard agent resources](https://learn.microsoft.com/azure/foundry/agents/concepts/standard-agent-setup)
* [Capability hosts](https://learn.microsoft.com/azure/foundry/agents/concepts/capability-hosts)
* [Add a connection to a Foundry project](https://learn.microsoft.com/azure/foundry/how-to/connections-add)
* [Microsoft Foundry architecture](https://learn.microsoft.com/azure/foundry/concepts/architecture)
* [Authentication and authorization: control plane and data plane](https://learn.microsoft.com/azure/foundry/concepts/authentication-authorization-foundry#control-plane-and-data-plane)
* [Azure control plane and data plane](https://learn.microsoft.com/azure/azure-resource-manager/management/control-plane-and-data-plane)
* [Managed identities for Azure resources](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview)
* [What is Azure RBAC?](https://learn.microsoft.com/azure/role-based-access-control/overview)
* [Access tokens in the Microsoft identity platform](https://learn.microsoft.com/entra/identity-platform/access-tokens)
* [Microsoft Foundry Control Plane](https://learn.microsoft.com/azure/foundry/control-plane/overview)
* [Foundry Agent Service limits, quotas, and regional support](https://learn.microsoft.com/azure/foundry/agents/concepts/limits-quotas-regions)
* [Foundry model deployment types and data processing](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/deployment-types)
* [What is Foundry IQ?](https://learn.microsoft.com/azure/foundry/agents/concepts/what-is-foundry-iq)
* [Foundry IQ frequently asked questions](https://learn.microsoft.com/azure/foundry/agents/concepts/foundry-iq-faq)
* [Vector search in Azure AI Search](https://learn.microsoft.com/azure/search/vector-search-overview)
* [Agentic retrieval in Azure AI Search](https://learn.microsoft.com/azure/search/agentic-retrieval-overview)
* [Model Context Protocol introduction](https://modelcontextprotocol.io/introduction)

### API and data-plane implementation

* [Microsoft Foundry API reference](https://ai.azure.com/api-reference)
* [Microsoft Foundry Project REST API](https://learn.microsoft.com/rest/api/microsoft-foundry/aiproject)
* [Azure AI Search Data Plane REST API](https://learn.microsoft.com/rest/api/searchservice/)
* [Show the current Azure CLI signed-in user](https://learn.microsoft.com/cli/azure/ad/signed-in-user#az-ad-signed-in-user-show)
* [Show a Microsoft Entra service principal](https://learn.microsoft.com/cli/azure/ad/sp#az-ad-sp-show)
* [Connect agents to Foundry IQ knowledge bases](https://learn.microsoft.com/azure/foundry/agents/how-to/foundry-iq-connect?tabs=foundry%2Crest)
* [Build an agentic retrieval solution](https://learn.microsoft.com/azure/search/agentic-retrieval-how-to-create-pipeline)
* [Create a Blob knowledge source](https://learn.microsoft.com/azure/search/agentic-knowledge-source-how-to-blob)
* [Index CSV blobs with `delimitedText`](https://learn.microsoft.com/azure/search/search-how-to-index-azure-blob-csv)
* [Map fields and document keys in indexers](https://learn.microsoft.com/azure/search/search-indexer-field-mappings)
* [Azure AI Search 2026-05-01-preview REST specification](https://raw.githubusercontent.com/Azure/azure-rest-api-specs/refs/heads/main/specification/search/data-plane/Search/preview/2026-05-01-preview/search.json)
* [Knowledge Sources REST API](https://learn.microsoft.com/rest/api/searchservice/knowledge-sources?view=rest-searchservice-2026-04-01)
* [Knowledge Bases REST API](https://learn.microsoft.com/rest/api/searchservice/knowledge-bases?view=rest-searchservice-2026-04-01)
* [Knowledge Retrieval REST API](https://learn.microsoft.com/rest/api/searchservice/knowledge-retrieval/retrieve?view=rest-searchservice-2026-04-01&tabs=HTTP)

### Official samples and specifications

* [Microsoft Foundry samples](https://github.com/microsoft-foundry/foundry-samples)
* [Terraform Standard agent setup sample](https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-terraform/41-standard-agent-setup)
* [Microsoft Foundry REST quickstart sample](https://github.com/microsoft-foundry/foundry-samples/tree/main/samples/REST/quickstart)
* [Microsoft Foundry Data Plane TypeSpec](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/ai-foundry/data-plane/Foundry)
* [Cognitive Services ARM Control Plane TypeSpec](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/CognitiveServices.Management)
* [Azure AI Search Data Plane specification](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/search/data-plane/Search)
