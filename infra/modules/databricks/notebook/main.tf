resource "databricks_notebook" "this" {
  path           = var.path
  language       = var.language
  content_base64 = var.content_base64
}
