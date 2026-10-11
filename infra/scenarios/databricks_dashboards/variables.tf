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
