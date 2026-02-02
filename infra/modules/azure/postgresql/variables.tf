variable "name" {
  description = "Base name for the PostgreSQL Flexible Server"
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

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "administrator_login" {
  description = "Administrator login for PostgreSQL Flexible Server"
  type        = string
  default     = "psqladmin"
}

variable "administrator_password" {
  description = "Administrator password for PostgreSQL Flexible Server"
  type        = string
  sensitive   = true
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "17"
}

variable "sku_name" {
  description = "SKU name for PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "zone" {
  description = "Availability zone for PostgreSQL Flexible Server"
  type        = string
  default     = "2"
}
