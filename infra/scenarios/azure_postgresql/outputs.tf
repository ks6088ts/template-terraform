output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "postgresql_server_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server"
  value       = module.postgresql.server_fqdn
}

output "postgresql_database_name" {
  description = "Name of the database"
  value       = azurerm_postgresql_flexible_server_database.this.name
}

output "postgresql_administrator_login" {
  description = "Administrator login"
  value       = module.postgresql.administrator_login
}

output "postgresql_administrator_password" {
  description = "Administrator password (auto-generated unless provided)"
  value       = local.administrator_password
  sensitive   = true
}

output "postgresql_connection_uri" {
  description = "Connection URI for psql (sslmode=require)"
  value       = "postgresql://${var.administrator_login}:${urlencode(local.administrator_password)}@${module.postgresql.server_fqdn}:5432/${var.database_name}?sslmode=require"
  sensitive   = true
}
