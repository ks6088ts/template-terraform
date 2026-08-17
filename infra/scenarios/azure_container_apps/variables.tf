variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "azurecontainerapps"
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
    scenario        = "azure_container_apps"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

variable "container_image" {
  description = "OCI container image to deploy (e.g., nginx:latest or a public ACR image)"
  type        = string
  default     = "nginx:latest"

  validation {
    condition     = length(var.container_image) > 0
    error_message = "Container image must not be empty."
  }
}

variable "enable_public_acr" {
  description = "Whether to deploy an Azure Container Registry with anonymous pull access"
  type        = bool
  default     = false
}

variable "acr_sku" {
  description = "SKU for the public Azure Container Registry (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be one of: Standard, Premium."
  }
}

variable "container_command" {
  description = "Command to run in the container (overrides the image entrypoint)"
  type        = list(string)
  default     = []
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}

variable "cpu" {
  description = "CPU cores allocated to the container (e.g., 0.25, 0.5, 1.0)"
  type        = number
  default     = 0.25

  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.cpu)
    error_message = "CPU must be one of: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0."
  }
}

variable "memory" {
  description = "Memory allocated to the container (e.g., 0.5Gi, 1Gi)"
  type        = string
  default     = "0.5Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.memory))
    error_message = "Memory must be in format like '0.5Gi', '1Gi', '2Gi'."
  }
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 0

  validation {
    condition     = var.min_replicas >= 0 && var.min_replicas <= 300
    error_message = "Minimum replicas must be between 0 and 300."
  }
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 3

  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 300
    error_message = "Maximum replicas must be between 1 and 300."
  }
}

variable "env_vars" {
  description = "Environment variables to inject into the container. Use 'value' for plain values or 'secret_name' to reference a secret defined in 'secrets'."
  type = list(object({
    name        = string
    value       = optional(string)
    secret_name = optional(string)
  }))
  default = []
}

variable "secrets" {
  description = "Secrets to define on the Container App, referenced by env_vars via 'secret_name'."
  type = list(object({
    name  = string
    value = string
  }))
  default   = []
  sensitive = true
}

variable "enable_application_insights" {
  description = "Whether to deploy Application Insights and inject its connection string into the Container App as a secret-backed environment variable (APPLICATIONINSIGHTS_CONNECTION_STRING)."
  type        = bool
  default     = true
}

variable "application_insights_type" {
  description = "Type of Application Insights to create (e.g., web, java, MobileCenter, Node.JS, other)"
  type        = string
  default     = "web"

  validation {
    condition     = contains(["web", "java", "MobileCenter", "Node.JS", "other"], var.application_insights_type)
    error_message = "application_insights_type must be one of: web, java, MobileCenter, Node.JS, other."
  }
}

variable "application_insights_sampling_percentage" {
  description = "Telemetry sampling percentage for Application Insights (0-100). 100 means no sampling."
  type        = number
  default     = 100

  validation {
    condition     = var.application_insights_sampling_percentage >= 0 && var.application_insights_sampling_percentage <= 100
    error_message = "application_insights_sampling_percentage must be between 0 and 100."
  }
}

variable "enable_authentication" {
  description = "Whether to protect the Container App with Microsoft Entra ID built-in authentication (Easy Auth). Unauthenticated requests receive HTTP 401."
  type        = bool
  default     = false
}

variable "azure_cli_client_id" {
  description = "Client ID of the Microsoft Azure CLI public client application used for interactive user authentication"
  type        = string
  default     = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_cli_client_id))
    error_message = "azure_cli_client_id must be a valid UUID."
  }
}
