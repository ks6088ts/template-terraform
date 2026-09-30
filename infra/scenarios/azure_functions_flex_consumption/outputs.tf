output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "subscription_id" {
  description = "Azure subscription ID containing the Function App"
  value       = data.azurerm_client_config.current.subscription_id
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = module.log_analytics.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = module.log_analytics.name
}

output "log_analytics_workspace_customer_id" {
  description = "Workspace customer ID used to query Log Analytics"
  value       = module.log_analytics.workspace_id
}

output "application_insights_id" {
  description = "ID of the Application Insights resource"
  value       = module.application_insights.id
}

output "application_insights_name" {
  description = "Name of the Application Insights resource"
  value       = module.application_insights.name
}

output "application_insights_app_id" {
  description = "Application ID of the Application Insights resource"
  value       = module.application_insights.app_id
}

output "function_app_id" {
  description = "ID of the Function App"
  value       = module.functions_flex_consumption.function_app_id
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = module.functions_flex_consumption.function_app_name
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = module.functions_flex_consumption.function_app_default_hostname
}

output "function_app_url" {
  description = "Full URL to access the Function App"
  value       = module.functions_flex_consumption.function_app_url
}

output "function_app_principal_id" {
  description = "Principal ID of the Function App's System Assigned Managed Identity"
  value       = module.functions_flex_consumption.function_app_principal_id
}

output "function_app_authentication_client_id" {
  description = "Client ID of the Microsoft Entra application used for Function App authentication"
  value       = azuread_application.function_app.client_id
}

output "function_app_authentication_identifier_uri" {
  description = "Application ID URI used to request an access token for the Function App"
  value       = azuread_application_identifier_uri.function_app.identifier_uri
}

output "function_app_authentication_tenant_id" {
  description = "Microsoft Entra tenant ID used for Function App authentication"
  value       = data.azuread_client_config.current.tenant_id
}

output "service_plan_id" {
  description = "ID of the Service Plan"
  value       = module.functions_flex_consumption.service_plan_id
}

output "service_plan_name" {
  description = "Name of the Service Plan"
  value       = module.functions_flex_consumption.service_plan_name
}

output "storage_account_id" {
  description = "ID of the Storage Account"
  value       = module.functions_flex_consumption.storage_account_id
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = module.functions_flex_consumption.storage_account_name
}

output "deployment_container_name" {
  description = "Name of the deployment package container used by the Storage probe"
  value       = module.functions_flex_consumption.deployment_container_name
}

output "timer_schedule" {
  description = "Configured NCRONTAB timer trigger schedule"
  value       = var.timer_schedule
}
