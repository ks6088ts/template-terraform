output "databricks_host" {
  description = "HTTPS workspace URL used by the Databricks provider"
  value       = local.databricks_host
}

output "dashboards" {
  description = "Visible AI/BI dashboards matching the optional name filter, with dashboard_id, display_name, and create_time"
  value       = module.dashboards.dashboards
}

output "dashboard_count" {
  description = "Number of visible AI/BI dashboards matching the optional name filter"
  value       = module.dashboards.dashboard_count
}
