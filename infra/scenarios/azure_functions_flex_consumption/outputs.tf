output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
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
