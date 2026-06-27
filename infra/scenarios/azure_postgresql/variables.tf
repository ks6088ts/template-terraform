variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "azurepostgresql"
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
    scenario        = "azure_postgresql"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server
# -----------------------------------------------------------------------------

variable "administrator_login" {
  description = "Administrator login for PostgreSQL Flexible Server"
  type        = string
  default     = "psqladmin"
}

variable "administrator_password" {
  description = "Administrator password. Leave unset to auto-generate a strong password (see outputs)."
  type        = string
  sensitive   = true
  default     = null
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "postgresql_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "17"
}

variable "sku_name" {
  description = "SKU name for PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"
}
