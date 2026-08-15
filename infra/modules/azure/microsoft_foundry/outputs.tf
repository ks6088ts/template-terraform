output "account_id" {
  description = "The ID of the Microsoft Foundry account"
  value       = azapi_resource.account.id
}

output "account_name" {
  description = "The name of the Microsoft Foundry account"
  value       = azapi_resource.account.name
}

output "account_endpoint" {
  description = "The endpoint of the Microsoft Foundry account"
  value       = "https://${var.name}.cognitiveservices.azure.com/"
}

output "openai_endpoint" {
  description = "The Azure OpenAI endpoint of the Microsoft Foundry account"
  value       = "https://${var.name}.openai.azure.com/"
}

output "project_id" {
  description = "The ID of the Microsoft Foundry project"
  value       = azapi_resource.project.id
}

output "project_endpoint" {
  description = "The data-plane endpoint of the Microsoft Foundry project"
  value       = "https://${var.name}.services.ai.azure.com/api/projects/${azapi_resource.project.name}"
}

output "project_principal_id" {
  description = "The principal ID of the Microsoft Foundry project"
  value       = azapi_resource.project.output.identity.principalId
}

output "project_name" {
  description = "The name of the Microsoft Foundry project"
  value       = azapi_resource.project.name
}

output "deployment_ids" {
  description = "The IDs of the model deployments"
  value       = { for k, v in azapi_resource.deployment : k => v.id }
}
