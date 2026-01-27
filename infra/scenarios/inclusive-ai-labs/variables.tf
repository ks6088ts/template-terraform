variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "inclusiveailabs"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "japaneast"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    scenario        = "inclusive-ai-labs"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

# -----------------------------------------------------------------------------
# inclusive-ai-labs Container Settings
# -----------------------------------------------------------------------------

variable "inclusive_ai_labs_image" {
  description = "Docker Hub image for inclusive-ai-labs"
  type        = string
  default     = "ks6088ts/inclusive-ai-labs:0.0.3"
}

variable "inclusive_ai_labs_cpu" {
  description = "CPU cores allocated to inclusive-ai-labs container"
  type        = number
  default     = 2.0

  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.inclusive_ai_labs_cpu)
    error_message = "CPU must be one of: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0."
  }
}

variable "inclusive_ai_labs_memory" {
  description = "Memory allocated to inclusive-ai-labs container"
  type        = string
  default     = "4Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.inclusive_ai_labs_memory))
    error_message = "Memory must be in format like '0.5Gi', '1Gi', '2Gi'."
  }
}

variable "inclusive_ai_labs_min_replicas" {
  description = "Minimum number of replicas for inclusive-ai-labs"
  type        = number
  default     = 1

  validation {
    condition     = var.inclusive_ai_labs_min_replicas >= 0 && var.inclusive_ai_labs_min_replicas <= 300
    error_message = "Minimum replicas must be between 0 and 300."
  }
}

variable "inclusive_ai_labs_max_replicas" {
  description = "Maximum number of replicas for inclusive-ai-labs"
  type        = number
  default     = 3

  validation {
    condition     = var.inclusive_ai_labs_max_replicas >= 1 && var.inclusive_ai_labs_max_replicas <= 300
    error_message = "Maximum replicas must be between 1 and 300."
  }
}

# -----------------------------------------------------------------------------
# voicevox Container Settings
# -----------------------------------------------------------------------------

variable "voicevox_image" {
  description = "Docker Hub image for voicevox"
  type        = string
  default     = "voicevox/voicevox_engine:cpu-ubuntu20.04-latest"
}

variable "voicevox_cpu" {
  description = "CPU cores allocated to voicevox container"
  type        = number
  default     = 2.0

  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.voicevox_cpu)
    error_message = "CPU must be one of: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0."
  }
}

variable "voicevox_memory" {
  description = "Memory allocated to voicevox container"
  type        = string
  default     = "4Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.voicevox_memory))
    error_message = "Memory must be in format like '0.5Gi', '1Gi', '2Gi'."
  }
}

variable "voicevox_min_replicas" {
  description = "Minimum number of replicas for voicevox"
  type        = number
  default     = 1

  validation {
    condition     = var.voicevox_min_replicas >= 0 && var.voicevox_min_replicas <= 300
    error_message = "Minimum replicas must be between 0 and 300."
  }
}

variable "voicevox_max_replicas" {
  description = "Maximum number of replicas for voicevox"
  type        = number
  default     = 3

  validation {
    condition     = var.voicevox_max_replicas >= 1 && var.voicevox_max_replicas <= 300
    error_message = "Maximum replicas must be between 1 and 300."
  }
}

# -----------------------------------------------------------------------------
# Ollama Container Settings
# -----------------------------------------------------------------------------

variable "ollama_image" {
  description = "Docker Hub image for Ollama"
  type        = string
  default     = "ollama/ollama:latest"
}

variable "ollama_model" {
  description = "Ollama model to pull on startup"
  type        = string
  default     = "gemma3:270m"
}

variable "ollama_cpu" {
  description = "CPU cores allocated to Ollama container"
  type        = number
  default     = 2.0

  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.ollama_cpu)
    error_message = "CPU must be one of: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0."
  }
}

variable "ollama_memory" {
  description = "Memory allocated to Ollama container"
  type        = string
  default     = "4Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.ollama_memory))
    error_message = "Memory must be in format like '0.5Gi', '1Gi', '2Gi'."
  }
}

variable "ollama_min_replicas" {
  description = "Minimum number of replicas for Ollama"
  type        = number
  default     = 1

  validation {
    condition     = var.ollama_min_replicas >= 0 && var.ollama_min_replicas <= 300
    error_message = "Minimum replicas must be between 0 and 300."
  }
}

variable "ollama_max_replicas" {
  description = "Maximum number of replicas for Ollama"
  type        = number
  default     = 1

  validation {
    condition     = var.ollama_max_replicas >= 1 && var.ollama_max_replicas <= 300
    error_message = "Maximum replicas must be between 1 and 300."
  }
}

variable "ollama_storage_quota_gb" {
  description = "Storage quota in GB for Ollama Azure File Share"
  type        = number
  default     = 10

  validation {
    condition     = var.ollama_storage_quota_gb >= 1 && var.ollama_storage_quota_gb <= 5120
    error_message = "Storage quota must be between 1 and 5120 GB."
  }
}

# -----------------------------------------------------------------------------
# Application Environment Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for the application"
  type        = string
  default     = "inclusive-ai-labs"
}

variable "project_log_level" {
  description = "Log level for the application"
  type        = string
  default     = "INFO"
}

variable "api_host" {
  description = "API server host"
  type        = string
  default     = "0.0.0.0"
}

variable "api_port" {
  description = "API server port"
  type        = number
  default     = 8000
}

variable "cors_origins" {
  description = "Comma-separated list of allowed CORS origins"
  type        = string
  default     = "[\"*\"]"
}

# GenAI Settings
variable "genai_default_provider" {
  description = "Default GenAI provider"
  type        = string
  default     = "ollama"
}

variable "genai_azure_openai_endpoint" {
  description = "Azure OpenAI endpoint URL"
  type        = string
  default     = ""
}

variable "genai_azure_openai_api_key" {
  description = "Azure OpenAI API key"
  type        = string
  default     = "api_key"
}

variable "genai_azure_openai_deployment_name" {
  description = "Azure OpenAI deployment name"
  type        = string
  default     = "gpt-4o"
}

variable "genai_azure_openai_api_version" {
  description = "Azure OpenAI API version"
  type        = string
  default     = "2024-02-15-preview"
}

# STT Settings
variable "stt_default_provider" {
  description = "Default STT provider"
  type        = string
  default     = "whisper"
}

variable "stt_whisper_model_size" {
  description = "Whisper model size"
  type        = string
  default     = "small"
}

variable "stt_whisper_device" {
  description = "Whisper device (cpu/cuda)"
  type        = string
  default     = "cpu"
}

variable "stt_whisper_compute_type" {
  description = "Whisper compute type"
  type        = string
  default     = "int8"
}

# TTS Settings
variable "tts_default_provider" {
  description = "Default TTS provider"
  type        = string
  default     = "voicevox"
}

variable "tts_default_voice" {
  description = "Default TTS voice"
  type        = string
  default     = "en_US-lessac-medium"
}

variable "tts_voicevox_default_speaker" {
  description = "Default voicevox speaker ID"
  type        = string
  default     = "1"
}

variable "tts_voicevox_timeout" {
  description = "Voicevox request timeout in seconds"
  type        = string
  default     = "30.0"
}
