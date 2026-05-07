# =============================================================================
# Data Sources
# =============================================================================

data "azurerm_client_config" "current" {}

# =============================================================================
# Local Variables
# =============================================================================

locals {
  # Construct CHATLOG_DSN based on authentication mode
  chatlog_dsn = var.chatlog_auth_mode == "password" ? (
    "postgresql+asyncpg://${var.postgresql_administrator_login}:${var.postgresql_administrator_password}@${module.postgresql.server_fqdn}:5432/${var.postgresql_database_name}?sslmode=require"
    ) : (
    # For entra mode, password is omitted (token-based auth)
    "postgresql+asyncpg://${var.postgresql_administrator_login}@${module.postgresql.server_fqdn}:5432/${var.postgresql_database_name}?sslmode=require"
  )
}

# =============================================================================
# Resource Group
# =============================================================================

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = var.name
  location = var.location
  tags     = var.tags
}

# =============================================================================
# Log Analytics Workspace
# =============================================================================

module "log_analytics" {
  source = "../../modules/azure/log_analytics"

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

# =============================================================================
# PostgreSQL Flexible Server
# =============================================================================

module "postgresql" {
  source = "../../modules/azure/postgresql"

  name                   = var.name
  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  tags                   = var.tags
  tenant_id              = data.azurerm_client_config.current.tenant_id
  administrator_login    = var.postgresql_administrator_login
  administrator_password = var.postgresql_administrator_password
  postgresql_version     = var.postgresql_version
  sku_name               = var.postgresql_sku_name
}

# Configure PostgreSQL extensions
resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = module.postgresql.server_id
  value     = "VECTOR,PG_TRGM"
}

# Create application database
resource "azurerm_postgresql_flexible_server_database" "chatlog" {
  name      = var.postgresql_database_name
  server_id = module.postgresql.server_id
}

# =============================================================================
# Container Apps Environment
# =============================================================================

resource "azurerm_container_app_environment" "this" {
  name                       = "env-${var.name}"
  location                   = module.resource_group.location
  resource_group_name        = module.resource_group.name
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = var.tags
}

# -----------------------------------------------------------------------------
# Azure Storage for Ollama model persistence
# -----------------------------------------------------------------------------
resource "azurerm_storage_account" "ollama" {
  name                     = substr("st${replace(var.name, "-", "")}ollama", 0, 24)
  resource_group_name      = module.resource_group.name
  location                 = module.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_share" "ollama" {
  name               = "ollama-data"
  storage_account_id = azurerm_storage_account.ollama.id
  quota              = var.ollama_storage_quota_gb
}

# Mount Azure Files to Container Apps Environment
resource "azurerm_container_app_environment_storage" "ollama" {
  name                         = "ollama-storage"
  container_app_environment_id = azurerm_container_app_environment.this.id
  account_name                 = azurerm_storage_account.ollama.name
  share_name                   = azurerm_storage_share.ollama.name
  access_key                   = azurerm_storage_account.ollama.primary_access_key
  access_mode                  = "ReadWrite"
}

# -----------------------------------------------------------------------------
# Ollama Container App (Internal only)
# -----------------------------------------------------------------------------
resource "azurerm_container_app" "ollama" {
  name                         = "app-ollama"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = module.resource_group.name
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    container {
      name   = "ollama"
      image  = var.ollama_image
      cpu    = var.ollama_cpu
      memory = var.ollama_memory

      # Custom entrypoint to pull model on startup
      command = ["/bin/sh", "-c"]
      args    = ["ollama serve & sleep 5 && ollama pull ${var.ollama_model} && wait"]

      # Environment variables
      env {
        name  = "OLLAMA_HOST"
        value = "0.0.0.0"
      }

      # Mount volume for model persistence
      volume_mounts {
        name = "ollama-data"
        path = "/root/.ollama"
      }

      # Health check probe
      liveness_probe {
        transport        = "HTTP"
        port             = 11434
        path             = "/"
        initial_delay    = 30
        interval_seconds = 30
      }

      readiness_probe {
        transport        = "HTTP"
        port             = 11434
        path             = "/"
        initial_delay    = 30
        interval_seconds = 10
      }
    }

    volume {
      name         = "ollama-data"
      storage_name = azurerm_container_app_environment_storage.ollama.name
      storage_type = "AzureFile"
    }

    min_replicas = var.ollama_min_replicas
    max_replicas = var.ollama_max_replicas
  }

  # Ingress configuration (internal or external based on variable)
  ingress {
    external_enabled = var.ollama_external_enabled
    target_port      = 11434
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# -----------------------------------------------------------------------------
# voicevox Container App (Internal only)
# -----------------------------------------------------------------------------
resource "azurerm_container_app" "voicevox" {
  name                         = "app-voicevox"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = module.resource_group.name
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    container {
      name   = "voicevox"
      image  = var.voicevox_image
      cpu    = var.voicevox_cpu
      memory = var.voicevox_memory

      # Health check probe
      liveness_probe {
        transport = "HTTP"
        port      = 50021
        path      = "/"
      }

      readiness_probe {
        transport = "HTTP"
        port      = 50021
        path      = "/"
      }
    }

    min_replicas = var.voicevox_min_replicas
    max_replicas = var.voicevox_max_replicas
  }

  # Internal ingress only (accessible within the same Container Apps Environment)
  ingress {
    external_enabled = false
    target_port      = 50021
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# -----------------------------------------------------------------------------
# azure_inclusive_ai_labs Container App (External)
# -----------------------------------------------------------------------------
resource "azurerm_container_app" "azure_inclusive_ai_labs" {
  name                         = "app-inclusive-ai-labs"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = module.resource_group.name
  revision_mode                = "Single"
  tags                         = var.tags

  # Secret for Azure OpenAI API Key
  secret {
    name  = "genai-azure-openai-api-key"
    value = var.genai_azure_openai_api_key
  }

  # Secret for GitHub Copilot Azure OpenAI API Key
  secret {
    name  = "github-copilot-azure-openai-api-key"
    value = var.github_copilot_azure_openai_api_key
  }

  # Secret for CHATLOG_DSN
  secret {
    name  = "chatlog-dsn"
    value = local.chatlog_dsn
  }

  # Enable System Assigned Managed Identity (required for Entra ID authentication)
  dynamic "identity" {
    for_each = var.chatlog_auth_mode == "entra" ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  template {
    container {
      name   = "inclusive-ai-labs"
      image  = var.azure_inclusive_ai_labs_image
      cpu    = var.azure_inclusive_ai_labs_cpu
      memory = var.azure_inclusive_ai_labs_memory

      # Command to run
      command = ["python", "scripts/api.py", "run", "--workers", "4"]

      # Environment variables
      env {
        name  = "PROJECT_NAME"
        value = var.project_name
      }
      env {
        name  = "PROJECT_LOG_LEVEL"
        value = var.project_log_level
      }
      env {
        name  = "PYTHONPATH"
        value = "/app"
      }
      env {
        name  = "API_HOST"
        value = var.api_host
      }
      env {
        name  = "API_PORT"
        value = tostring(var.api_port)
      }
      env {
        name  = "CORS_ORIGINS"
        value = var.cors_origins
      }

      # GenAI Settings
      env {
        name  = "GENAI_DEFAULT_PROVIDER"
        value = var.genai_default_provider
      }
      env {
        name  = "GENAI_AZURE_OPENAI_ENDPOINT"
        value = var.genai_azure_openai_endpoint
      }
      env {
        name        = "GENAI_AZURE_OPENAI_API_KEY"
        secret_name = "genai-azure-openai-api-key"
      }
      env {
        name  = "GENAI_AZURE_OPENAI_DEPLOYMENT_NAME"
        value = var.genai_azure_openai_deployment_name
      }
      env {
        name  = "GENAI_AZURE_OPENAI_API_VERSION"
        value = var.genai_azure_openai_api_version
      }
      env {
        name  = "GENAI_SYSTEM_PROMPT"
        value = var.genai_system_prompt
      }

      # Ollama Settings (internal communication via Container Apps internal DNS)
      env {
        name  = "GENAI_OLLAMA_BASE_URL"
        value = "http://app-ollama"
      }
      env {
        name  = "GENAI_OLLAMA_MODEL"
        value = var.ollama_model
      }

      # STT Settings
      env {
        name  = "STT_DEFAULT_PROVIDER"
        value = var.stt_default_provider
      }
      env {
        name  = "STT_WHISPER_MODEL_SIZE"
        value = var.stt_whisper_model_size
      }
      env {
        name  = "STT_WHISPER_DEVICE"
        value = var.stt_whisper_device
      }
      env {
        name  = "STT_WHISPER_COMPUTE_TYPE"
        value = var.stt_whisper_compute_type
      }
      env {
        name  = "STT_HF_HOME"
        value = var.stt_hf_home
      }

      # TTS Settings
      env {
        name  = "TTS_DEFAULT_PROVIDER"
        value = var.tts_default_provider
      }
      env {
        name  = "TTS_DEFAULT_VOICE"
        value = var.tts_default_voice
      }
      # Internal communication to voicevox via Container Apps internal DNS
      env {
        name  = "TTS_VOICEVOX_BASE_URL"
        value = "http://app-voicevox"
      }
      env {
        name  = "TTS_VOICEVOX_DEFAULT_SPEAKER"
        value = var.tts_voicevox_default_speaker
      }
      env {
        name  = "TTS_VOICEVOX_TIMEOUT"
        value = var.tts_voicevox_timeout
      }
      env {
        name  = "TTS_PIPER_VOICES_DIR"
        value = var.tts_piper_voices_dir
      }

      # GitHub Copilot Settings
      env {
        name  = "GITHUB_COPILOT_AUTH_MODE"
        value = var.github_copilot_auth_mode
      }
      env {
        name  = "GITHUB_COPILOT_BYOK_PROFILE"
        value = var.github_copilot_byok_profile
      }
      env {
        name  = "GITHUB_COPILOT_AZURE_OPENAI_MODEL"
        value = var.github_copilot_azure_openai_model
      }
      env {
        name  = "GITHUB_COPILOT_AZURE_OPENAI_ENDPOINT"
        value = var.github_copilot_azure_openai_endpoint
      }
      env {
        name        = "GITHUB_COPILOT_AZURE_OPENAI_API_KEY"
        secret_name = "github-copilot-azure-openai-api-key"
      }
      env {
        name  = "GITHUB_COPILOT_AZURE_OPENAI_API_VERSION"
        value = var.github_copilot_azure_openai_api_version
      }

      # CHATLOG Settings
      env {
        name  = "CHATLOG_ENABLED"
        value = tostring(var.chatlog_enabled)
      }
      env {
        name        = "CHATLOG_DSN"
        secret_name = "chatlog-dsn"
      }
      env {
        name  = "CHATLOG_AUTH_MODE"
        value = var.chatlog_auth_mode
      }
    }

    min_replicas = var.azure_inclusive_ai_labs_min_replicas
    max_replicas = var.azure_inclusive_ai_labs_max_replicas
  }

  # External ingress (publicly accessible)
  ingress {
    external_enabled = true
    target_port      = var.api_port
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  depends_on = [
    azurerm_container_app.voicevox,
    azurerm_container_app.ollama,
    module.postgresql,
    azurerm_postgresql_flexible_server_configuration.extensions,
    azurerm_postgresql_flexible_server_database.chatlog
  ]
}

# Configure Entra ID administrator (when using entra auth mode)
# This must be created after the Container App so we can reference its identity
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "entra_admin" {
  count = var.chatlog_auth_mode == "entra" ? 1 : 0

  server_name         = module.postgresql.server_name
  resource_group_name = module.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = azurerm_container_app.azure_inclusive_ai_labs.identity[0].principal_id
  principal_name      = azurerm_container_app.azure_inclusive_ai_labs.name
  principal_type      = "ServicePrincipal"

  depends_on = [
    azurerm_container_app.azure_inclusive_ai_labs
  ]
}
