variable "name" {
  description = "Base name for the container registry (alphanumeric only)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the container registry"
  type        = string
}

variable "sku" {
  description = "SKU for the container registry (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be one of: Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user for the container registry"
  type        = bool
  default     = false
}

variable "anonymous_pull_enabled" {
  description = "Enable anonymous pull access for all repositories in the container registry"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access for the container registry"
  type        = bool
  default     = true
}

variable "azuread_authentication_as_arm_policy_enabled" {
  description = "Use Azure Resource Manager audience tokens to authenticate to the registry"
  type        = bool
  default     = true
}

variable "role_assignment_mode" {
  description = "Role assignment mode for the container registry"
  type        = string
  default     = "LegacyRegistryPermissions"

  validation {
    condition     = contains(["LegacyRegistryPermissions", "AbacRepositoryPermissions"], var.role_assignment_mode)
    error_message = "Role assignment mode must be one of: LegacyRegistryPermissions, AbacRepositoryPermissions."
  }
}

variable "tags" {
  description = "Tags to apply to the container registry"
  type        = map(string)
  default     = {}
}
