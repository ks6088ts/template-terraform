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
  description = "Publisher portal URL of the API Management instance"
  value       = azurerm_api_management.this.portal_url
}

output "developer_portal_url" {
  description = "Developer portal URL of the API Management instance"
  value       = azurerm_api_management.this.developer_portal_url
}

output "public_ip_addresses" {
  description = "Public IP addresses of the API Management instance"
  value       = azurerm_api_management.this.public_ip_addresses
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity, or null when disabled"
  value       = var.enable_system_assigned_identity ? azurerm_api_management.this.identity[0].principal_id : null
}

output "identity_type" {
  description = "Managed identity type configured on the API Management instance, or null when no identity is configured"
  value       = local.identity_type
}

output "user_assigned_identity_ids" {
  description = "Resource IDs of user-assigned managed identities attached to the API Management instance"
  value       = var.user_assigned_identity_ids
}
