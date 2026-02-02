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

output "project_id" {
  description = "The ID of the Microsoft Foundry project"
  value       = azapi_resource.project.id
}

output "project_name" {
  description = "The name of the Microsoft Foundry project"
  value       = azapi_resource.project.name
}

output "deployment_ids" {
  description = "The IDs of the model deployments"
  value       = { for k, v in azapi_resource.deployment : k => v.id }
}
