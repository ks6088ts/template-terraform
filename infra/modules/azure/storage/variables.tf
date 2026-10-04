variable "name" {
  description = "Base name for the Storage Account resources"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the Storage Account (must be globally unique, 3-24 lowercase letters and numbers)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage Account name must contain 3 to 24 lowercase letters or numbers."
  }
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

variable "enable_hns" {
  description = "Enable hierarchical namespace (Data Lake Storage Gen2)"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "allow_nested_items_to_be_public" {
  description = "Allow nested items to be public"
  type        = bool
  default     = false
}

variable "https_traffic_only_enabled" {
  description = "Enable HTTPS traffic only"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key"
  type        = bool
  default     = true
}

variable "enable_identity" {
  description = "Enable a system-assigned managed identity"
  type        = bool
  default     = true
}

variable "enable_blob_soft_delete" {
  description = "Enable soft delete for blobs"
  type        = bool
  default     = false
}

variable "blob_soft_delete_retention_days" {
  description = "Number of days to retain soft deleted blobs"
  type        = number
  default     = 7
}

variable "container_soft_delete_retention_days" {
  description = "Number of days to retain soft deleted containers"
  type        = number
  default     = 7
}

variable "create_queue" {
  description = "Create a storage queue"
  type        = bool
  default     = false
}

variable "queue_data_contributor_principal_id" {
  description = "Optional principal object ID granted Storage Queue Data Contributor when the queue is created"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.queue_data_contributor_principal_id == null || trimspace(var.queue_data_contributor_principal_id) != ""
    error_message = "Queue data contributor principal ID must be null or a non-empty string."
  }
}

variable "create_container" {
  description = "Create a storage container"
  type        = bool
  default     = false
}

variable "container_name" {
  description = "Name of the storage container"
  type        = string
  default     = "default"
}

variable "container_access_type" {
  description = "Access type for the container (private, blob, container)"
  type        = string
  default     = "private"
}
