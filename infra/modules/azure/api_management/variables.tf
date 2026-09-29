variable "name" {
  description = "Name of the API Management instance"
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 50 && can(regex("^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$", var.name))
    error_message = "The API Management name must be 1-50 characters, contain only letters, numbers, and hyphens, and start and end with a letter or number."
  }
}

variable "location" {
  description = "Azure region for the API Management instance"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "publisher_name" {
  description = "Publisher name for the API Management instance"
  type        = string
}

variable "publisher_email" {
  description = "Publisher email for the API Management instance"
  type        = string
}

variable "sku_name" {
  description = "SKU tier and capacity of the API Management instance, in the <tier>_<capacity> format"
  type        = string

  validation {
    condition     = can(regex("^(Consumption|Developer|Basic|BasicV2|Standard|StandardV2|Premium|PremiumV2)_[0-9]+$", var.sku_name))
    error_message = "The sku_name must be a valid tier (Consumption, Developer, Basic, BasicV2, Standard, StandardV2, Premium, PremiumV2) followed by an underscore and a non-negative capacity, e.g. Developer_1."
  }
}

variable "enable_system_assigned_identity" {
  description = "Enable a system-assigned managed identity for the API Management instance"
  type        = bool
  default     = false
}

variable "user_assigned_identity_ids" {
  description = "Resource IDs of user-assigned managed identities to attach to the API Management instance"
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for id in var.user_assigned_identity_ids :
      can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.ManagedIdentity/userAssignedIdentities/[^/]+$", id))
    ])
    error_message = "user_assigned_identity_ids must contain valid Microsoft.ManagedIdentity/userAssignedIdentities resource IDs."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled for the API Management instance"
  type        = bool
  default     = true
}

variable "virtual_network_type" {
  description = "Virtual network mode for the API Management instance"
  type        = string
  default     = "None"

  validation {
    condition     = contains(["None", "External", "Internal"], var.virtual_network_type)
    error_message = "virtual_network_type must be None, External, or Internal."
  }
}

variable "virtual_network_subnet_id" {
  description = "Resource ID of the subnet used for API Management virtual network integration"
  type        = string
  default     = null

  validation {
    condition     = var.virtual_network_subnet_id == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.virtual_network_subnet_id))
    error_message = "virtual_network_subnet_id must be a valid virtual network subnet resource ID."
  }
}

variable "tags" {
  description = "Tags to apply to the API Management instance"
  type        = map(string)
  default     = {}
}
