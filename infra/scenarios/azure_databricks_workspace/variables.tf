variable "name" {
  description = "Base name for the Azure Databricks resources"
  type        = string
  default     = "azuredatabricks"
  nullable    = false

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 32 && can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])$", var.name))
    error_message = "Name must contain 3 to 32 lowercase letters, numbers, or hyphens and must start and end with a letter or number."
  }
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
  default     = "japaneast"
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

variable "tags" {
  description = "Tags to apply to the resource group and workspace"
  type        = map(string)
  nullable    = false
  default = {
    scenario        = "azure_databricks_workspace"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}
