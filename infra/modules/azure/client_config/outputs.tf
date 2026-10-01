output "client_id" {
  description = "Client ID of the authenticated Azure principal"
  value       = data.azurerm_client_config.current.client_id
}

output "object_id" {
  description = "Object ID of the authenticated Azure principal"
  value       = data.azurerm_client_config.current.object_id
}

output "subscription_id" {
  description = "Azure subscription ID used by the provider"
  value       = data.azurerm_client_config.current.subscription_id
}

output "tenant_id" {
  description = "Microsoft Entra tenant ID used by the provider"
  value       = data.azurerm_client_config.current.tenant_id
}
