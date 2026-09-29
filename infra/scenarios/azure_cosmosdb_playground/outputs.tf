output "resource_group_name" {
  value       = module.resource_group.name
  description = "Resource group containing the playground"
}

output "cosmos_account_name" {
  value       = module.cosmosdb.account_name
  description = "Cosmos DB account name"
}

output "cosmos_endpoint" {
  value       = module.cosmosdb.account_endpoint
  description = "Public HTTPS Cosmos DB endpoint"
}

output "cosmos_database_name" {
  value       = local.database_name
  description = "NoSQL database name"
}

output "cosmos_container_name" {
  value       = local.container_name
  description = "NoSQL container name"
}

output "foundry_endpoint" {
  value       = module.microsoft_foundry.openai_endpoint
  description = "OpenAI-compatible Foundry endpoint"
}

output "embedding_deployment_name" {
  value       = var.embedding_model.name
  description = "Embedding deployment name"
}

output "chat_deployment_name" {
  value       = var.chat_model.name
  description = "Answer deployment name"
}

output "vector_dimensions" {
  value       = var.vector_dimensions
  description = "Vector index dimensions"
}
