locals {
  databricks_host = "https://${var.workspace_url}"
}

module "dashboards" {
  source = "../../modules/databricks/dashboards"

  dashboard_name_contains = var.dashboard_name_contains
}
