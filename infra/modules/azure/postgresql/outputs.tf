output "server_id" {
  description = "ID of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.this.id
}

output "server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.this.name
}

output "server_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "administrator_login" {
  description = "Administrator login of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.this.administrator_login
}
