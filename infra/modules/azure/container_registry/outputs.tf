output "id" {
  description = "ID of the container registry"
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Login server URL of the container registry"
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  description = "Admin username of the container registry"
  value       = azurerm_container_registry.this.admin_username
}

output "admin_password" {
  description = "Admin password of the container registry"
  value       = azurerm_container_registry.this.admin_password
  sensitive   = true
}
