---
description: Scenario for deploying an inclusive AI conversation system to Azure Container Apps
---

# azure_inclusive_ai_labs

This Terraform scenario deploys the azure_inclusive_ai_labs application to Azure Container Apps. It combines speech recognition (STT), AI conversation (GenAI), and speech synthesis (TTS) to build an **inclusive AI conversation system**.

## 🎯 What This Scenario Provides

* **Speech-to-Text conversion**: Converts the user's speech to text
* **AI conversation** (Generative AI): Generates an AI response from the text
* **Text-to-Speech conversion**: Reads the AI response aloud

This creates an accessible system that enables people with visual impairments or people who cannot use their hands to interact with AI through speech.

## 📦 Deployed Components

| Component                      | Role                                        | External access                                                                                         |
|--------------------------------|---------------------------------------------|---------------------------------------------------------------------------------------------------------|
| **azure_inclusive_ai_labs**    | Main API server (conversation orchestrator) | ✅ Available                                                                                             |
| **voicevox**                   | Japanese speech synthesis engine            | ❌ Internal only                                                                                         |
| **ollama**                     | Local LLM runtime engine                    | ❌ Internal only (configurable)                                                                          |
| **PostgreSQL Flexible Server** | Chatlog database (`chatlog`)                 | ✅ Available (public network) / ⚠️ Not created by default (enable with `postgresql_enabled = true`)      |

## 🏗️ System Architecture

### Overall Architecture

```mermaid
flowchart TB
    subgraph Internet["🌐 Internet"]
        User["👤 User"]
    end

    subgraph Azure["☁️ Azure Cloud"]
        subgraph RG["📁 Resource Group (rg-azureinclusiveailabs)"]
            subgraph CAE["🔷 Container Apps Environment"]
                direction TB

                subgraph External["Externally Accessible Service"]
                    IAL["🎯 azure_inclusive_ai_labs<br/>(Main API)<br/>Port: 8000"]
                end

                subgraph Internal["Internal Services"]
                    VV["🎤 voicevox<br/>(Speech Synthesis)<br/>Port: 50021"]
                    OL["🧠 ollama<br/>(Local LLM)<br/>Port: 11434"]
                end
            end

            LAW["📊 Log Analytics<br/>(Log Monitoring)"]
            Storage["💾 Azure Storage<br/>(Model Persistence)"]
            PostgreSQL["🐘 PostgreSQL Flexible Server<br/>chatlog DB<br/>extensions: VECTOR, PG_TRGM"]
        end

        AOAI["🤖 Azure OpenAI<br/>(Cloud LLM)"]
    end

    User -->|"HTTPS Request"| IAL
    IAL -->|"Internal HTTP"| VV
    IAL -->|"Internal HTTP"| OL
    IAL -->|"TLS 5432"| PostgreSQL
    IAL -.->|"HTTPS (Optional)"| AOAI
    CAE --> LAW
    OL --> Storage

    style IAL fill:#4CAF50,color:#fff
    style VV fill:#2196F3,color:#fff
    style OL fill:#9C27B0,color:#fff
    style AOAI fill:#FF9800,color:#fff
```

### Azure Resource Architecture

```mermaid
flowchart LR
    subgraph Resources["Azure Resource List"]
        direction TB
        RG["📁 azurerm_resource_group"]
        LAW["📊 azurerm_log_analytics_workspace"]
        CAE["🔷 azurerm_container_app_environment"]
        SA["💾 azurerm_storage_account"]
        FS["📂 azurerm_storage_share"]
        ES["🔗 azurerm_container_app_environment_storage"]
        CA1["📦 azurerm_container_app<br/>(azure_inclusive_ai_labs)"]
        CA2["📦 azurerm_container_app<br/>(voicevox)"]
        CA3["📦 azurerm_container_app<br/>(ollama)"]
        PGS["🐘 azurerm_postgresql_flexible_server"]
        PGC["⚙️ azurerm_postgresql_flexible_server_configuration<br/>(azure.extensions)"]
        PGD["🗄️ azurerm_postgresql_flexible_server_database<br/>(chatlog)"]
    end

    RG --> LAW
    RG --> SA
    LAW --> CAE
    SA --> FS
    FS --> ES
    ES --> CAE
    CAE --> CA1
    CAE --> CA2
    CAE --> CA3
    RG --> PGS
    PGS --> PGC
    PGS --> PGD
    CA1 --> PGD
```

## 🔄 Processing Flow

### Voice Conversation Flow

```mermaid
sequenceDiagram
    autonumber
    participant User as 👤 User
    participant API as 🎯 azure_inclusive_ai_labs
    participant STT as 🎧 STT Module<br/>(Whisper)
    participant LLM as 🧠 GenAI Module<br/>(Ollama / Azure OpenAI)
    participant TTS as 🎤 TTS Module<br/>(voicevox / piper)

    User->>+API: Send audio data
    Note over API: Receive audio file

    API->>+STT: Request speech-to-text conversion
    STT-->>-API: Text "Hello"
    Note over API: Speech recognition complete

    API->>+LLM: Ask AI a question using text
    Note over LLM: Use Ollama or Azure OpenAI<br/>depending on the provider
    LLM-->>-API: Response "Hello! How can I help you?"
    Note over API: AI response generation complete

    API->>+TTS: Request conversion of response text to speech
    Note over TTS: Use voicevox (Japanese) or piper (multilingual)<br/>depending on the language
    TTS-->>-API: Audio data (WAV)
    Note over API: Speech synthesis complete

    API-->>-User: Return audio data
    Note over User: Listen to the spoken response
```

### API Request Processing Details

```mermaid
flowchart TD
    Start["🚀 Request Received"] --> Parse["📝 Parse Request"]
    Parse --> Decision{"🔀 Determine Processing Type"}

    Decision -->|"Audio Input"| STT["🎧 STT Module<br/>(Whisper)"]
    Decision -->|"Text Input"| GenAI

    STT --> GenAI["🧠 GenAI Module"]

    GenAI --> ProviderCheck{"🔄 Select GenAI<br/>Provider"}
    ProviderCheck -->|"ollama"| Ollama["🏠 Ollama<br/>(Local LLM)"]
    ProviderCheck -->|"azure-openai"| AOAI["☁️ Azure OpenAI<br/>(Cloud LLM)"]

    Ollama --> Response["📄 Text Response"]
    AOAI --> Response

    Response --> TTSCheck{"🔊 Audio Output?"}
    TTSCheck -->|"Yes"| TTSModule["🎤 TTS Module"]
    TTSCheck -->|"No"| TextOut["📤 Return Text"]

    TTSModule --> TTSProvider{"🔄 Select TTS<br/>Provider"}
    TTSProvider -->|"Japanese"| VV["🎤 voicevox<br/>(Optimized for Japanese)"]
    TTSProvider -->|"Multilingual"| Piper["🎤 piper<br/>(Multilingual)"]

    VV --> AudioOut["🔈 Return Audio"]
    Piper --> AudioOut

    TextOut --> End["✅ Complete"]
    AudioOut --> End

    style Ollama fill:#9C27B0,color:#fff
    style AOAI fill:#FF9800,color:#fff
    style VV fill:#2196F3,color:#fff
    style Piper fill:#00BCD4,color:#fff
```

## 🔀 Multiple Provider Support

azure_inclusive_ai_labs is designed to **switch between multiple providers** for each **STT (speech recognition)**, **GenAI (generative AI)**, and **TTS (speech synthesis)** module. You can select the provider that best fits your use case and requirements.

### Supported Providers

```mermaid
flowchart TB
    subgraph STT["🎧 STT (Speech Recognition) Module"]
        direction LR
        STT_IF["Unified Interface"]
        STT_W["✅ Whisper<br/>(Currently Supported)"]
        STT_Future["🔮 Future Extension"]
        STT_IF --> STT_W
        STT_IF -.-> STT_Future
    end

    subgraph GenAI["🧠 GenAI (Generative AI) Module"]
        direction LR
        GENAI_IF["Unified Interface"]
        GENAI_OL["✅ Ollama<br/>(Local LLM)"]
        GENAI_AO["✅ Azure OpenAI<br/>(Cloud LLM)"]
        GENAI_IF --> GENAI_OL
        GENAI_IF --> GENAI_AO
    end

    subgraph TTS["🎤 TTS (Speech Synthesis) Module"]
        direction LR
        TTS_IF["Unified Interface"]
        TTS_VV["✅ voicevox<br/>(For Japanese)"]
        TTS_PP["✅ piper<br/>(For Multiple Languages)"]
        TTS_IF --> TTS_VV
        TTS_IF --> TTS_PP
    end

    style STT_W fill:#4CAF50,color:#fff
    style GENAI_OL fill:#9C27B0,color:#fff
    style GENAI_AO fill:#FF9800,color:#fff
    style TTS_VV fill:#2196F3,color:#fff
    style TTS_PP fill:#00BCD4,color:#fff
```

### Module Details

| Module    | Provider     | Supported languages and uses | Features                                                        |
|-----------|--------------|------------------------------|-----------------------------------------------------------------|
| **STT**   | Whisper      | Multilingual (100+ languages) | High-accuracy speech recognition model developed by OpenAI      |
| **GenAI** | Ollama       | Multilingual                 | Runs locally, keeps data from leaving the environment, and free |
| **GenAI** | Azure OpenAI | Multilingual                 | High-performance models such as GPT-4o and enterprise support   |
| **TTS**   | voicevox     | 🇯🇵 **Optimized for Japanese** | High-quality Japanese speech and character voices               |
| **TTS**   | piper        | 🌍 **Multilingual support**   | Lightweight and fast support for English, German, French, and more |

### Provider Selection Flow

```mermaid
flowchart TD
    subgraph Selection["Provider Selection Criteria"]
        Start["📝 Review Requirements"] --> Lang{"🌐 Target Language?"}

        Lang -->|"Primarily Japanese"| TTS_JP["TTS: voicevox Recommended"]
        Lang -->|"English or Multilingual"| TTS_ML["TTS: piper Recommended"]

        Start --> Privacy{"🔒 Data Sensitivity?"}
        Privacy -->|"High (No External Transmission)"| LLM_Local["GenAI: Ollama Recommended"]
        Privacy -->|"Standard"| LLM_Cloud["GenAI: Azure OpenAI Recommended"]

        Start --> Performance{"⚡ Performance Requirements?"}
        Performance -->|"Highest Quality"| LLM_Cloud
        Performance -->|"Cost Priority"| LLM_Local
    end

    style TTS_JP fill:#2196F3,color:#fff
    style TTS_ML fill:#00BCD4,color:#fff
    style LLM_Local fill:#9C27B0,color:#fff
    style LLM_Cloud fill:#FF9800,color:#fff
```

### Switching Providers with Environment Variables

| Environment variable     | Value                     | Description                                                |
|--------------------------|---------------------------|------------------------------------------------------------|
| `GENAI_DEFAULT_PROVIDER` | `ollama` / `azure-openai` | LLM provider to use                                        |
| `TTS_DEFAULT_PROVIDER`   | `voicevox` / `piper`      | Speech synthesis provider to use                           |
| `STT_DEFAULT_PROVIDER`   | `whisper`                 | Speech recognition provider to use                         |
| `CHATLOG_ENABLED`        | `true` / `false`          | Enables the Chatlog feature                                |
| `CHATLOG_AUTH_MODE`      | `password` / `entra`      | Chatlog authentication mode                                |
| `CHATLOG_DSN`            | Secret reference          | PostgreSQL connection DSN (through a Container Apps Secret) |

## 🔗 Inter-Container Communication

```mermaid
flowchart TB
    subgraph CAE["Container Apps Environment"]
        direction TB

        subgraph DNS["Internal DNS"]
            D1["app-inclusive-ai-labs"]
            D2["app-voicevox"]
            D3["app-ollama"]
        end

        IAL["azure_inclusive_ai_labs"]
        VV["voicevox"]
        OL["ollama"]

        D1 -.-> IAL
        D2 -.-> VV
        D3 -.-> OL
    end

    IAL -->|"http://app-voicevox:80"| VV
    IAL -->|"http://app-ollama:80"| OL
```

Within the same Container Apps environment, applications can communicate directly by application name.

* `http://app-voicevox` → voicevox container
* `http://app-ollama` → ollama container

## 📊 Monitoring and Logs

```mermaid
flowchart LR
    subgraph Apps["Applications"]
        CA1["azure_inclusive_ai_labs"]
        CA2["voicevox"]
        CA3["ollama"]
    end

    subgraph Monitoring["Monitoring Platform"]
        LAW["📊 Log Analytics<br/>Workspace"]
    end

    CA1 -->|"Send Logs"| LAW
    CA2 -->|"Send Logs"| LAW
    CA3 -->|"Send Logs"| LAW

    LAW --> Query["🔍 Log Search"]
    LAW --> Alert["⚠️ Alert Configuration"]
    LAW --> Dashboard["📈 Dashboard"]
```

## ⚙️ Prerequisites

* Azure subscription
* Azure OpenAI resource with a deployed model (when using Azure OpenAI)

Configure the common [Azure authentication](../../../docs/tips/provider-authentication.md),
[Terraform workflow](../../../docs/tips/terraform-workflow.md), and, when needed,
[Azure Blob Storage backend](../../../docs/tips/azure-blob-backend.md).
Specify `SCENARIO=azure_inclusive_ai_labs` when running Makefile commands for this scenario.

## 🚀 Quick Start

1. **Create a `terraform.tfvars` file**

   ```hcl
   name     = "azureinclusiveailabs"
   location = "japaneast"

    # Azure OpenAI settings (required when using Azure OpenAI)
   genai_azure_openai_endpoint = "https://your-openai-resource.openai.azure.com/"
   genai_azure_openai_api_key  = "your-api-key-here"
   genai_azure_openai_deployment_name = "gpt-4o"

    # Use the local LLM (Ollama) by default
   genai_default_provider = "ollama"
    ollama_model = "gemma3:270m"  # Default model

    # Chatlog (PostgreSQL) settings: entra (passwordless) mode by default
    # Chatlog (PostgreSQL) settings
    # PostgreSQL Flexible Server is not created by default (postgresql_enabled = false)
    # To use chatlog, explicitly specify the following settings
   # postgresql_enabled                = true
   # chatlog_enabled                   = true
   #
    # To use password mode, override the settings as follows
   # postgresql_administrator_password = "YourSecurePassword123!"
   # chatlog_auth_mode                 = "password"
   ```

2. **Deploy**

    Follow the [standard Terraform workflow](../../../docs/tips/terraform-workflow.md) to deploy
    `SCENARIO=azure_inclusive_ai_labs`.

3. **Access the application**

    The URL is available as an output after deployment completes.

   ```bash
   terraform output azure_inclusive_ai_labs_url
   ```

### Enable PostgreSQL (chatlog)

To reduce costs and the initial deployment footprint, **PostgreSQL Flexible Server is not created by default** (`postgresql_enabled = false`). Enable it explicitly in `terraform.tfvars` as shown below only when using the chatlog feature.

```hcl
# Create PostgreSQL Flexible Server and its related resources (chatlog DB, extensions, and Entra administrator)
postgresql_enabled = true

# Also enable the application's chatlog feature (requires postgresql_enabled = true)
chatlog_enabled = true
```

When `postgresql_enabled = false`, none of the following resources are created, and `CHATLOG_DSN` is set to an empty string.

* `module.postgresql` (the `azurerm_postgresql_flexible_server` resource and firewall rule)
* `azurerm_postgresql_flexible_server_configuration.azure_extensions`
* `azurerm_postgresql_flexible_server_database.chatlog`
* `azurerm_postgresql_flexible_server_active_directory_administrator.chatlog`

> [!IMPORTANT]
> Setting `chatlog_enabled = true` also requires `postgresql_enabled = true` (otherwise validation fails).

### Deploy with Password Authentication

To use `chatlog_auth_mode = "password"`, add the following settings.

```hcl
chatlog_auth_mode                 = "password"
postgresql_administrator_password = "YourSecurePassword123!"
```

### Deploy with Entra Authentication

The default is `chatlog_auth_mode = "entra"`. To set it explicitly, use the following configuration.

```hcl
chatlog_auth_mode = "entra"
tenant_id         = "<your-entra-tenant-id>" # When omitted, uses the current Azure CLI sign-in tenant
```

> [!IMPORTANT]
> In `entra` mode, you must separately bootstrap the login role in PostgreSQL (grant membership in the `azure_ad_user` role). The initial phase assumes that you perform this step manually by connecting as the PostgreSQL administrator after `terraform apply`.
>
> Example:
>
> ```sql
> CREATE ROLE "app-inclusive-ai-labs" WITH LOGIN IN ROLE azure_ad_user;
> GRANT ALL PRIVILEGES ON DATABASE chatlog TO "app-inclusive-ai-labs";
> ```
>
> To run the commands, connect using a command such as `psql "host=<postgresql_server_fqdn> dbname=postgres user=<postgres_admin> sslmode=require"`, then execute the SQL above.

## 📋 Variables

### Required Variables

| Name                          | Description                          |
|-------------------------------|--------------------------------------|
| `genai_azure_openai_api_key` | Azure OpenAI API key (sensitive data) |

### Basic Settings

| Name       | Default value           | Description        |
|------------|-------------------------|--------------------|
| `name`     | `azureinclusiveailabs` | Base resource name |
| `location` | `japaneast`            | Azure region       |

### PostgreSQL / Chatlog Settings

> [!WARNING]
> **PostgreSQL Flexible Server is not created by default.** To use it, explicitly set `postgresql_enabled = true`. For details, see [Enable PostgreSQL (chatlog)](#enable-postgresql-chatlog).

| Name                                | Default value      | Description                                                                                                        |
|-------------------------------------|--------------------|--------------------------------------------------------------------------------------------------------------------|
| `postgresql_enabled`                | `false`            | Whether to create PostgreSQL Flexible Server. When `true`, creates all chatlog resources (server, DB, extensions, and Entra administrator) |
| `postgresql_administrator_login`    | `psqladmin`        | PostgreSQL administrator user                                                                                      |
| `postgresql_administrator_password` | `null`             | PostgreSQL administrator password (required and must be non-empty when `chatlog_auth_mode=password`)               |
| `postgresql_database_name`          | `chatlog`          | Application database name                                                                                          |
| `postgresql_sku_name`               | `B_Standard_B1ms`  | PostgreSQL SKU                                                                                                     |
| `postgresql_version`                | `17`               | PostgreSQL version                                                                                                 |
| `chatlog_auth_mode`                 | `entra`            | Chatlog authentication mode (`password` / `entra`)                                                                 |
| `chatlog_enabled`                   | `false`            | Enables the application's Chatlog feature (`postgresql_enabled = true` is required when set to `true`)             |
| `tenant_id`                         | `""`               | Entra tenant ID (automatically retrieved from the current Azure client when empty)                                 |

### azure_inclusive_ai_labs Container Settings

| Name                                    | Default value                         | Description      |
|-----------------------------------------|---------------------------------------|------------------|
| `azure_inclusive_ai_labs_image`         | `ks6088ts/inclusive-ai-labs:latest` | Docker image     |
| `azure_inclusive_ai_labs_cpu`           | `2.0`                                 | Number of CPU cores |
| `azure_inclusive_ai_labs_memory`        | `4Gi`                                 | Memory           |
| `azure_inclusive_ai_labs_min_replicas`  | `1`                                   | Minimum replicas |
| `azure_inclusive_ai_labs_max_replicas`  | `3`                                   | Maximum replicas |

### voicevox Container Settings

| Name                    | Default value                                     | Description         |
|-------------------------|---------------------------------------------------|---------------------|
| `voicevox_image`        | `voicevox/voicevox_engine:cpu-ubuntu20.04-latest` | Docker image        |
| `voicevox_cpu`          | `2.0`                                             | Number of CPU cores |
| `voicevox_memory`       | `4Gi`                                             | Memory              |
| `voicevox_min_replicas` | `1`                                               | Minimum replicas    |
| `voicevox_max_replicas` | `3`                                               | Maximum replicas    |

### Ollama Container Settings

| Name                      | Default value            | Description                    |
|---------------------------|--------------------------|--------------------------------|
| `ollama_image`            | `ollama/ollama:latest` | Docker image                   |
| `ollama_model`            | `gemma3:270m`          | Model to download at startup   |
| `ollama_cpu`              | `2.0`                  | Number of CPU cores            |
| `ollama_memory`           | `4Gi`                  | Memory                         |
| `ollama_storage_quota_gb` | `10`                   | Storage capacity (GB)          |
| `ollama_external_enabled` | `false`                | Whether to expose externally   |

### AI / Speech Processing Settings

| Name                                  | Default value                   | Description                                  |
|---------------------------------------|---------------------------------|----------------------------------------------|
| `genai_default_provider`              | `ollama`                        | LLM provider (`ollama` or `azure-openai`)    |
| `genai_system_prompt`                 | `You are a helpful assistant.`  | System prompt for the GenAI provider         |
| `genai_azure_openai_endpoint`         | ``                              | Azure OpenAI endpoint URL                    |
| `genai_azure_openai_deployment_name`  | `gpt-4o`                        | Deployment name                              |
| `genai_azure_openai_api_version`      | `2024-02-15-preview`            | Azure OpenAI API version                     |
| `stt_default_provider`                | `whisper`                       | Speech recognition provider                  |
| `stt_whisper_model_size`              | `small`                         | Whisper model size                           |
| `stt_whisper_device`                  | `cpu`                           | Whisper device (`cpu` / `cuda`)              |
| `stt_whisper_compute_type`            | `int8`                          | Whisper compute type                         |
| `stt_hf_home`                         | ``                              | Hugging Face model cache directory           |
| `tts_default_provider`                | `voicevox`                      | Speech synthesis provider                    |
| `tts_default_voice`                   | `en_US-lessac-medium`           | Default voice (for piper)                    |
| `tts_voicevox_default_speaker`        | `1`                             | voicevox speaker ID                          |
| `tts_voicevox_timeout`                | `30.0`                          | voicevox request timeout (seconds)            |
| `tts_piper_voices_dir`                | ``                              | Piper voice model directory                  |

For details, see [variables.tf](variables.tf).

## 📤 Outputs

| Name                            | Description                                     |
|---------------------------------|-------------------------------------------------|
| `azure_inclusive_ai_labs_url`   | Public URL of the azure_inclusive_ai_labs API   |
| `azure_inclusive_ai_labs_fqdn`  | FQDN of the Container App                       |
| `voicevox_internal_fqdn`        | Internal FQDN of voicevox                       |
| `ollama_internal_fqdn`          | Internal FQDN of ollama                         |
| `ollama_url`                    | ollama URL (external / internal)                |
| `postgresql_server_fqdn`        | FQDN of PostgreSQL Flexible Server              |
| `postgresql_database_name`      | Database name for Chatlog                       |
| `chatlog_dsn`                   | DSN for the Chatlog connection (sensitive)      |

## 🔗 Internal Communication

The `azure_inclusive_ai_labs` container communicates with the other containers through internal DNS in the Container Apps environment.

```mermaid
flowchart LR
    subgraph CAE["Container Apps Environment"]
        IAL["azure_inclusive_ai_labs"]
        VV["voicevox"]
        OL["ollama"]

        IAL -->|"TTS_VOICEVOX_BASE_URL<br/>http://app-voicevox"| VV
        IAL -->|"GENAI_OLLAMA_BASE_URL<br/>http://app-ollama"| OL
    end
```

These values are configured automatically through environment variables.

* `TTS_VOICEVOX_BASE_URL=http://app-voicevox`
* `GENAI_OLLAMA_BASE_URL=http://app-ollama`

## 🗑️ Delete Resources

Specify `SCENARIO=azure_inclusive_ai_labs` and follow the
[standard Terraform workflow](../../../docs/tips/terraform-workflow.md) to delete the resources.

## 💡 Use Cases

### Use Case 1: Accessible AI Assistant

```mermaid
flowchart TB
    subgraph User["Users"]
        Blind["👤 Person with a Visual Impairment"]
        Elder["👴 Older Adult"]
        Hands["🙋 Person Whose Hands Are Occupied"]
    end

    subgraph System["System"]
        Voice["🎙️ Voice Input"]
        AI["🧠 AI Processing"]
        Speech["🔊 Voice Output"]
    end

    User -->|"Speak"| Voice
    Voice --> AI
    AI --> Speech
    Speech -->|"Respond with Speech"| User
```

### Use Case 2: Multilingual Conversation System

```mermaid
flowchart LR
    subgraph Input["Voice Input"]
        JP["🇯🇵 Japanese Speech"]
        EN["🇺🇸 English Speech"]
        DE["🇩🇪 German Speech"]
    end

    subgraph STT_Module["STT Module"]
        STT["🎧 Whisper<br/>(Multilingual)"]
    end

    subgraph GenAI_Module["GenAI Module"]
        LLM["🧠 Ollama / Azure OpenAI"]
    end

    subgraph TTS_Module["TTS Module"]
        VV["🎤 voicevox<br/>(Japanese)"]
        PP["🎤 piper<br/>(English, German, and More)"]
    end

    subgraph Output["Voice Output"]
        OutJP["🔊 Japanese Speech"]
        OutEN["🔊 English Speech"]
    end

    JP --> STT
    EN --> STT
    DE --> STT
    STT --> LLM
    LLM --> VV
    LLM --> PP
    VV --> OutJP
    PP --> OutEN

    style VV fill:#2196F3,color:#fff
    style PP fill:#00BCD4,color:#fff
```

## ⚠️ Important Notes

* **voicevox** may take 1 to 2 minutes to start because it loads a language model
* **ollama** takes additional time during its first startup because it downloads the model
* The minimum replica count is set to 1 to avoid cold starts
* To optimize costs in a development environment, you can set `min_replicas` to 0
* Ollama model data is persisted in Azure Storage and remains available after container restarts
* PostgreSQL Flexible Server may need to restart after applying the `azure.extensions` configuration (`VECTOR,PG_TRGM`)
* ⚠️ **Important**: The PostgreSQL module creates an `AllowAll` firewall rule (`0.0.0.0-255.255.255.255`). This configuration is intended for testing. Always add access restrictions in production (for example, restrict `azurerm_postgresql_flexible_server_firewall_rule` to specific IP ranges, or implement the planned VNet / Private Endpoint support).

## 📚 Related Resources

* [Azure Container Apps documentation](https://learn.microsoft.com/ja-jp/azure/container-apps/)
* [voicevox engine](https://github.com/VOICEVOX/voicevox_engine)
* [Ollama](https://ollama.ai/)
* [OpenAI Whisper](https://github.com/openai/whisper)
* [Azure OpenAI Service](https://learn.microsoft.com/ja-jp/azure/ai-services/openai/)

## 🔧 Troubleshooting

### Container Fails to Start

```mermaid
flowchart TD
    Start["Container Startup Failure"] --> Check1{"Check Logs"}
    Check1 -->|"Insufficient Memory"| Fix1["Increase memory"]
    Check1 -->|"Image Pull Failure"| Fix2["Check Image Name"]
    Check1 -->|"Health Check Failure"| Fix3["Allow Startup Time"]

    Fix1 --> Retry["Redeploy with terraform apply"]
    Fix2 --> Retry
    Fix3 --> Wait["Wait 2-3 Minutes and Check Again"]
```

### Check Logs

```bash
# Check logs with Azure CLI
az containerapp logs show \
  --name app-inclusive-ai-labs \
  --resource-group rg-azureinclusiveailabs \
  --type console
```
