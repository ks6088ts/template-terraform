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

output "medallion" {
  description = "Medallion catalog, dedicated schema names, fully qualified table names, and Notebook path/URL; null when disabled. Tables are created by running the Notebook, not by Terraform."
  value = var.medallion_catalog_name == null ? null : {
    catalog_name = var.medallion_catalog_name
    schemas = {
      for layer, schema in module.medallion_schema : layer => schema.name
    }
    tables        = local.medallion_tables
    notebook_path = module.medallion_notebook[0].path
    notebook_url  = module.medallion_notebook[0].url
  }
}
