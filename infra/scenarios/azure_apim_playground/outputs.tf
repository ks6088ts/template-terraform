output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "api_management_id" {
  description = "ID of the API Management instance"
  value       = module.api_management.id
}

output "api_management_name" {
  description = "Name of the API Management instance"
  value       = module.api_management.name
}

output "api_management_gateway_url" {
  description = "Gateway URL of the API Management instance"
  value       = module.api_management.gateway_url
}

output "api_management_management_api_url" {
  description = "Management API URL of the API Management instance"
  value       = module.api_management.management_api_url
}

output "api_management_portal_url" {
  description = "Developer Portal URL of the API Management instance"
  value       = module.api_management.portal_url
}
