provider "databricks" {
  host      = local.databricks_host
  auth_type = "azure-cli"
}
