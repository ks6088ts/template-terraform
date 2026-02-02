variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "azuredatastore"
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
    scenario        = "azure_datastore"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

# =============================================================================
# Deploy flags (default: false)
# =============================================================================

variable "deploy_cosmosdb" {
  description = "Deploy Cosmos DB account with SQL database and container"
  type        = bool
  default     = false
}

variable "deploy_storage_account" {
  description = "Deploy Storage Account with Data Lake Storage (HNS) and Queue"
  type        = bool
  default     = false
}

variable "deploy_keyvault" {
  description = "Deploy Azure Key Vault"
  type        = bool
  default     = false
}

variable "deploy_postgresql" {
  description = "Deploy Azure Database for PostgreSQL Flexible Server"
  type        = bool
  default     = false
}

variable "deploy_monitor_workspace" {
  description = "Deploy Azure Monitor Workspace"
  type        = bool
  default     = false
}

# =============================================================================
# Cosmos DB configuration
# =============================================================================

variable "cosmosdb_consistency_level" {
  description = "Consistency level for Cosmos DB"
  type        = string
  default     = "BoundedStaleness"

  validation {
    condition     = contains(["BoundedStaleness", "Eventual", "Session", "Strong", "ConsistentPrefix"], var.cosmosdb_consistency_level)
    error_message = "Consistency level must be one of: BoundedStaleness, Eventual, Session, Strong, ConsistentPrefix."
  }
}

variable "cosmosdb_partition_key_path" {
  description = "Partition key path for Cosmos DB SQL container"
  type        = string
  default     = "/partitionKey"
}

# =============================================================================
# Storage Account configuration
# =============================================================================

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be Standard or Premium."
  }
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

# =============================================================================
# Key Vault configuration
# =============================================================================

variable "keyvault_sku_name" {
  description = "SKU name for Key Vault"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.keyvault_sku_name)
    error_message = "Key Vault SKU must be standard or premium."
  }
}

# =============================================================================
# PostgreSQL configuration
# =============================================================================

variable "postgresql_administrator_login" {
  description = "Administrator login for PostgreSQL Flexible Server"
  type        = string
  default     = "psqladmin"
}

variable "postgresql_administrator_password" {
  description = "Administrator password for PostgreSQL Flexible Server. Required when deploy_postgresql is true."
  type        = string
  sensitive   = true
  default     = null
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "17"

  validation {
    condition     = contains(["11", "12", "13", "14", "15", "16", "17"], var.postgresql_version)
    error_message = "PostgreSQL version must be one of: 11, 12, 13, 14, 15, 16, 17."
  }
}

variable "postgresql_sku_name" {
  description = "SKU name for PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgresql_zone" {
  description = "Availability zone for PostgreSQL Flexible Server"
  type        = string
  default     = "2"
}
