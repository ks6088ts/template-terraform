data "databricks_dashboards" "this" {
  dashboard_name_contains = var.dashboard_name_contains
}
