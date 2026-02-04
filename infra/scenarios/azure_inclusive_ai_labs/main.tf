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
    azurerm_container_app.ollama
  ]
}
