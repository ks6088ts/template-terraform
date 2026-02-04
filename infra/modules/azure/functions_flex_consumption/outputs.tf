output "function_app_id" {
  description = "ID of the Function App"
  value       = azurerm_function_app_flex_consumption.this.id
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_function_app_flex_consumption.this.name
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_function_app_flex_consumption.this.default_hostname
}

output "function_app_url" {
  description = "Full URL to access the Function App"
  value       = "https://${azurerm_function_app_flex_consumption.this.default_hostname}"
}

output "function_app_principal_id" {
  description = "Principal ID of the Function App's System Assigned Managed Identity"
  value       = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}

output "function_app_tenant_id" {
  description = "Tenant ID of the Function App's System Assigned Managed Identity"
  value       = azurerm_function_app_flex_consumption.this.identity[0].tenant_id
}

output "service_plan_id" {
  description = "ID of the Service Plan"
  value       = azurerm_service_plan.this.id
}

output "service_plan_name" {
  description = "Name of the Service Plan"
  value       = azurerm_service_plan.this.name
}

output "storage_account_id" {
  description = "ID of the Storage Account"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.this.name
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob endpoint of the Storage Account"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "deployment_container_name" {
  description = "Name of the deployment container"
  value       = azurerm_storage_container.deployment.name
}
