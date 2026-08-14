output "id" {
  description = "ID of the Azure AI Search service"
  value       = azurerm_search_service.this.id
}

output "name" {
  description = "Name of the Azure AI Search service"
  value       = azurerm_search_service.this.name
}

output "endpoint" {
  description = "Endpoint of the Azure AI Search service"
  value       = azurerm_search_service.this.endpoint
}

output "identity_principal_id" {
  description = "Principal ID of the Azure AI Search system-assigned managed identity"
  value       = var.enable_identity ? azurerm_search_service.this.identity[0].principal_id : null
}

output "primary_key" {
  description = "Primary admin key of the Azure AI Search service"
  value       = azurerm_search_service.this.primary_key
  sensitive   = true
}
