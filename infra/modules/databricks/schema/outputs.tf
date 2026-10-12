output "id" {
  description = "Provider-returned fully qualified schema name"
  value       = databricks_schema.this.id
}

output "name" {
  description = "Schema name within the catalog"
  value       = databricks_schema.this.name
}

output "catalog_name" {
  description = "Parent catalog name"
  value       = databricks_schema.this.catalog_name
}
