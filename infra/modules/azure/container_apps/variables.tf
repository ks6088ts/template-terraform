variable "name" {
  description = "Base name for the Container Apps resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  type        = string
}

variable "container_image" {
  description = "Docker image to deploy"
  type        = string
}

variable "cpu" {
  description = "CPU cores allocated to the container"
  type        = number
  default     = 0.25
}

variable "memory" {
  description = "Memory allocated to the container"
  type        = string
  default     = "0.5Gi"
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 3
}

variable "revision_mode" {
  description = "Revision mode for the Container App"
  type        = string
  default     = "Single"
}

variable "enable_ingress" {
  description = "Whether to enable ingress"
  type        = bool
  default     = true
}

variable "external_enabled" {
  description = "Whether ingress is externally enabled"
  type        = bool
  default     = true
}

variable "target_port" {
  description = "Target port for ingress"
  type        = number
  default     = 80
}

variable "container_command" {
  description = "Command to run in the container (overrides the image entrypoint)"
  type        = list(string)
  default     = []
}

variable "identity_type" {
  description = "Type of managed identity to assign to the Container App. Set to null to disable. Valid values: SystemAssigned, UserAssigned, 'SystemAssigned, UserAssigned'."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], coalesce(var.identity_type, "SystemAssigned"))
    error_message = "identity_type must be one of: SystemAssigned, UserAssigned, 'SystemAssigned, UserAssigned', or null."
  }
}

variable "identity_ids" {
  description = "List of user assigned managed identity IDs. Required when identity_type includes UserAssigned."
  type        = list(string)
  default     = []
}

variable "env_vars" {
  description = "Environment variables to inject into the container. Use 'value' for plain values or 'secret_name' to reference a secret defined in 'secrets'."
  type = list(object({
    name        = string
    value       = optional(string)
    secret_name = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for e in var.env_vars : (e.value == null) != (e.secret_name == null)
    ])
    error_message = "Each env_var must set exactly one of 'value' or 'secret_name'."
  }
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
