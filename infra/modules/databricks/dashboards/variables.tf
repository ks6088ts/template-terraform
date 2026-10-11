variable "dashboard_name_contains" {
  description = "Optional case-insensitive substring of the dashboard display name; null or an empty string reads all visible dashboards"
  type        = string
  default     = null
}
