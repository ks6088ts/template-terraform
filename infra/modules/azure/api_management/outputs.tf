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

output "public_ip_addresses" {
  description = "Public IP addresses of the API Management instance"
  value       = azurerm_api_management.this.public_ip_addresses
}
