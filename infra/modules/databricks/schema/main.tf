resource "databricks_schema" "this" {
  catalog_name  = var.catalog_name
  name          = var.name
  comment       = var.comment
  force_destroy = var.force_destroy
}
