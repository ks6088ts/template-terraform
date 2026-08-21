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

output "ai_gateway_openai_url" {
  description = "API Management URL prefix for Azure OpenAI requests"
  value       = "${module.api_management.gateway_url}/${var.gateway_api_path}"
}

output "api_management_principal_id" {
  description = "Principal ID of the API Management managed identity"
  value       = module.api_management.principal_id
}

output "microsoft_foundry_account_name" {
  description = "Name of the Microsoft Foundry account"
  value       = module.microsoft_foundry.account_name
}

output "microsoft_foundry_openai_endpoint" {
  description = "Direct Azure OpenAI endpoint of the Microsoft Foundry account"
  value       = module.microsoft_foundry.openai_endpoint
}

output "model_deployment_names" {
  description = "Names of the deployed Azure OpenAI models"
  value       = keys(module.microsoft_foundry.deployment_ids)
}
