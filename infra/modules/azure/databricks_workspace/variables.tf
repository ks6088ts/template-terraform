variable "name" {
  description = "Name of the Azure Databricks workspace"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{3,64}$", var.name))
    error_message = "Workspace name must contain 3 to 64 letters, numbers, underscores, or hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group containing the workspace"
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "Resource group name must not be empty."
  }
}

variable "location" {
  description = "Azure region for the workspace"
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "Location must not be empty."
  }
}

variable "sku" {
  description = "SKU for the Azure Databricks workspace"
  type        = string
  default     = "premium"
  nullable    = false

  validation {
    condition     = contains(["standard", "premium", "trial"], var.sku)
    error_message = "Workspace SKU must be standard, premium, or trial."
  }
}

variable "managed_resource_group_name" {
  description = "Optional name for the Databricks-managed resource group; Azure generates a name when omitted"
  type        = string
  default     = null

  validation {
    condition     = var.managed_resource_group_name == null ? true : trimspace(var.managed_resource_group_name) != ""
    error_message = "Managed resource group name must be null or a non-empty string."
  }
}

variable "tags" {
  description = "Tags to apply to the workspace"
  type        = map(string)
  default     = {}
  nullable    = false
}
