variable "workspace_url" {
  description = "Workspace DNS hostname without a scheme or path, such as the workspace_url output of azure_databricks_workspace"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.workspace_url) <= 253 && can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$", var.workspace_url))
    error_message = "Workspace URL must be a DNS hostname of at most 253 characters, without a scheme, path, port, or whitespace. Pass the workspace_url output, not databricks_host."
  }
}

variable "dashboard_name_contains" {
  description = "Optional case-insensitive substring of the dashboard display name; null or an empty string reads all visible dashboards"
  type        = string
  default     = null
}

variable "medallion_catalog_name" {
  description = "Existing Unity Catalog catalog with managed storage; null disables the medallion hands-on and preserves read-only dashboard lookup"
  type        = string
  default     = null

  validation {
    condition = var.medallion_catalog_name == null ? true : (
      can(regex("^[A-Za-z0-9_][A-Za-z0-9_-]{0,254}$", var.medallion_catalog_name)) &&
      !contains(["hive_metastore", "system"], lower(var.medallion_catalog_name))
    )
    error_message = "Medallion catalog must be null or an existing writable Unity Catalog name with 1-255 ASCII letters, numbers, underscores, or hyphens, not starting with a hyphen. hive_metastore and system are not supported."
  }
}

variable "medallion_schema_prefix" {
  description = "Dedicated disposable schema and Notebook prefix; 1-248 lowercase ASCII letters, numbers, or underscores, starting with a letter"
  type        = string
  default     = "medallion_playground"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,247}$", var.medallion_schema_prefix))
    error_message = "Medallion schema prefix must contain 1-248 lowercase ASCII letters, numbers, or underscores and start with a letter, leaving room for the layer suffix within the 255-character schema name limit."
  }
}
