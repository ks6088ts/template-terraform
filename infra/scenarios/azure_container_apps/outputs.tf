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
