variable "name" {
  description = "Base name for the Storage Account resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group (used for unique naming)"
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

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Storage account tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Storage account replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled"
  type        = bool
  default     = false
}

variable "enable_identity" {
  description = "Whether to enable system-assigned managed identity"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint"
  type        = bool
  default     = true
}

variable "virtual_network_id" {
  description = "ID of the virtual network for private DNS zone link"
  type        = string
  default     = ""
}

variable "private_endpoint_subnet_id" {
  description = "ID of the subnet for the private endpoint"
  type        = string
  default     = ""
}
