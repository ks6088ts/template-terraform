variable "name" {
  description = "Base name for the Microsoft Foundry resources"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
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

variable "disable_local_auth" {
  description = "Disable key-based local authentication for the Microsoft Foundry account"
  type        = bool
  default     = false
}

variable "project_display_name" {
  description = "Display name for the Foundry project"
  type        = string
  default     = "project"
}

variable "project_description" {
  description = "Description for the Foundry project"
  type        = string
  default     = "My first project"
}

variable "model_deployments" {
  description = "Model deployments to create in the Microsoft Foundry account"
  type = list(object({
    format                 = optional(string, "OpenAI")
    name                   = string
    model                  = string
    version                = string
    sku_name               = optional(string, "GlobalStandard")
    capacity               = number
    version_upgrade_option = optional(string, "NoAutoUpgrade")
  }))
  default = []

  validation {
    condition     = length(var.model_deployments) == length(distinct([for deployment in var.model_deployments : deployment.name]))
    error_message = "Model deployment names must be unique."
  }

  validation {
    condition = alltrue([
      for deployment in var.model_deployments :
      deployment.capacity > 0 && floor(deployment.capacity) == deployment.capacity
    ])
    error_message = "Model deployment capacity must be a positive integer measured in thousands of tokens per minute."
  }

  validation {
    condition = alltrue([
      for deployment in var.model_deployments :
      contains(
        ["NoAutoUpgrade", "OnceCurrentVersionExpired", "OnceNewDefaultVersionAvailable"],
        deployment.version_upgrade_option,
      )
    ])
    error_message = "version_upgrade_option must be NoAutoUpgrade, OnceCurrentVersionExpired, or OnceNewDefaultVersionAvailable."
  }
}
