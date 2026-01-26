# Resource Group
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name}"
  location = var.location
  tags     = var.tags
}

# Log Analytics Workspace (required for Container Apps Environment)
resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Container Apps Environment
resource "azurerm_container_app_environment" "this" {
  name                       = "env-${var.name}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  tags                       = var.tags
}

# -----------------------------------------------------------------------------
# voicevox Container App (Internal only)
# -----------------------------------------------------------------------------
resource "azurerm_container_app" "voicevox" {
  name                         = "app-voicevox"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
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
# inclusive-ai-labs Container App (External)
# -----------------------------------------------------------------------------
resource "azurerm_container_app" "inclusive_ai_labs" {
  name                         = "app-inclusive-ai-labs"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
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
      image  = var.inclusive_ai_labs_image
      cpu    = var.inclusive_ai_labs_cpu
      memory = var.inclusive_ai_labs_memory

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

    min_replicas = var.inclusive_ai_labs_min_replicas
    max_replicas = var.inclusive_ai_labs_max_replicas
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

  depends_on = [azurerm_container_app.voicevox]
}
