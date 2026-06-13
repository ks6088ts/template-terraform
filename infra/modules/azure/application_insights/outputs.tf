output "id" {
  description = "ID of the Application Insights resource"
  value       = azurerm_application_insights.this.id
}

output "name" {
  description = "Name of the Application Insights resource"
  value       = azurerm_application_insights.this.name
}

output "app_id" {
  description = "App ID associated with the Application Insights resource"
  value       = azurerm_application_insights.this.app_id
}

output "connection_string" {
  description = "Connection string for the Application Insights resource"
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "instrumentation_key" {
  description = "Instrumentation key for the Application Insights resource"
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}
