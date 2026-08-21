output "id" {
  description = "ID of the API Management instance"
  value       = azurerm_api_management.this.id
}

output "name" {
  description = "Name of the API Management instance"
  value       = azurerm_api_management.this.name
}

output "gateway_url" {
  description = "Gateway URL of the API Management instance"
  value       = azurerm_api_management.this.gateway_url
}

output "management_api_url" {
  description = "Management API URL of the API Management instance"
  value       = azurerm_api_management.this.management_api_url
}

output "portal_url" {
  description = "Developer Portal URL of the API Management instance"
  value       = azurerm_api_management.this.portal_url
}

output "principal_id" {
  description = "Principal ID of the API Management system-assigned managed identity"
  value       = try(azurerm_api_management.this.identity[0].principal_id, null)
}

output "public_ip_addresses" {
  description = "Public IP addresses of the API Management instance"
  value       = azurerm_api_management.this.public_ip_addresses
}
