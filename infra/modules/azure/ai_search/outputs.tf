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

output "primary_key" {
  description = "Primary admin key of the Azure AI Search service"
  value       = azurerm_search_service.this.primary_key
  sensitive   = true
}
