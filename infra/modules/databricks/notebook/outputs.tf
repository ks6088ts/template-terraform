output "path" {
  description = "Absolute Workspace notebook path"
  value       = databricks_notebook.this.path
}

output "url" {
  description = "Provider-returned routable Notebook URL"
  value       = databricks_notebook.this.url
}
