output "dashboards" {
  description = "Visible AI/BI dashboards matching the optional name filter, with provider-returned IDs, display names, and creation timestamps"
  value = [
    for dashboard in data.databricks_dashboards.this.dashboards : {
      dashboard_id = dashboard.dashboard_id
      display_name = dashboard.display_name
      create_time  = dashboard.create_time
    }
  ]
}

output "dashboard_count" {
  description = "Number of visible AI/BI dashboards matching the optional name filter"
  value       = length(data.databricks_dashboards.this.dashboards)
}
