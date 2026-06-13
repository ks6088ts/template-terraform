output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "container_app_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = module.container_apps.environment_id
}

output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = module.container_apps.environment_name
}

output "container_app_id" {
  description = "ID of the Container App"
  value       = module.container_apps.app_id
}

output "container_app_name" {
  description = "Name of the Container App"
  value       = module.container_apps.app_name
}

output "container_app_fqdn" {
  description = "FQDN of the Container App (external URL)"
  value       = module.container_apps.app_fqdn
}

output "container_app_url" {
  description = "Full URL to access the Container App"
  value       = module.container_apps.app_url
}

output "container_app_identity_principal_id" {
  description = "Principal ID of the Container App's system assigned managed identity"
  value       = module.container_apps.identity_principal_id
}

output "application_insights_id" {
  description = "ID of the Application Insights resource (null when disabled)"
  value       = var.enable_application_insights ? module.application_insights[0].id : null
}

output "application_insights_name" {
  description = "Name of the Application Insights resource (null when disabled)"
  value       = var.enable_application_insights ? module.application_insights[0].name : null
}

output "application_insights_connection_string" {
  description = "Connection string of the Application Insights resource (null when disabled)"
  value       = var.enable_application_insights ? module.application_insights[0].connection_string : null
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of the Application Insights resource (null when disabled)"
  value       = var.enable_application_insights ? module.application_insights[0].instrumentation_key : null
  sensitive   = true
}
