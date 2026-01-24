output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "container_app_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.this.id
}

output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.this.name
}

output "container_app_id" {
  description = "ID of the Container App"
  value       = azurerm_container_app.this.id
}

output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.this.name
}

output "container_app_fqdn" {
  description = "FQDN of the Container App (external URL)"
  value       = azurerm_container_app.this.ingress[0].fqdn
}

output "container_app_url" {
  description = "Full URL to access the Container App"
  value       = "https://${azurerm_container_app.this.ingress[0].fqdn}"
}
