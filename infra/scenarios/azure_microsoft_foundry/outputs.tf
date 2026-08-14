output "resource_group_name" {
  value       = module.resource_group.name
  description = "created resource group name"
}

output "microsoft_foundry_account_name" {
  value       = module.microsoft_foundry.account_name
  description = "Microsoft Foundry account name"
}

output "microsoft_foundry_account_endpoint" {
  value       = module.microsoft_foundry.account_endpoint
  description = "Microsoft Foundry account endpoint"
}

output "microsoft_foundry_project_name" {
  value       = module.microsoft_foundry.project_name
  description = "Microsoft Foundry project name"
}

output "azure_ai_search_id" {
  description = "ID of the Azure AI Search service"
  value       = var.deploy_standard_agent ? module.azure_ai_search[0].id : null
}

output "azure_ai_search_name" {
  description = "Name of the Azure AI Search service"
  value       = var.deploy_standard_agent ? module.azure_ai_search[0].name : null
}

output "azure_ai_search_endpoint" {
  description = "Endpoint of the Azure AI Search service"
  value       = var.deploy_standard_agent ? module.azure_ai_search[0].endpoint : null
}

output "azure_ai_search_connection_id" {
  description = "ID of the Azure AI Search connection in the Microsoft Foundry project"
  value       = var.deploy_standard_agent ? azapi_resource.azure_ai_search_connection[0].id : null
}

output "blob_storage_account_id" {
  description = "ID of the Azure Blob Storage account"
  value       = var.deploy_standard_agent ? module.blob_storage[0].account_id : null
}

output "blob_storage_account_name" {
  description = "Name of the Azure Blob Storage account"
  value       = var.deploy_standard_agent ? module.blob_storage[0].account_name : null
}

output "blob_storage_endpoint" {
  description = "Primary Blob endpoint of the Azure Blob Storage account"
  value       = var.deploy_standard_agent ? module.blob_storage[0].primary_blob_endpoint : null
}

output "blob_storage_connection_id" {
  description = "ID of the Azure Blob Storage connection in the Microsoft Foundry project"
  value       = var.deploy_standard_agent ? azapi_resource.blob_storage_connection[0].id : null
}

output "cosmosdb_account_id" {
  description = "ID of the Cosmos DB account used for agent threads"
  value       = var.deploy_standard_agent ? module.cosmosdb[0].account_id : null
}

output "cosmosdb_account_name" {
  description = "Name of the Cosmos DB account used for agent threads"
  value       = var.deploy_standard_agent ? module.cosmosdb[0].account_name : null
}

output "cosmosdb_endpoint" {
  description = "Endpoint of the Cosmos DB account used for agent threads"
  value       = var.deploy_standard_agent ? module.cosmosdb[0].account_endpoint : null
}

output "cosmosdb_connection_id" {
  description = "ID of the Cosmos DB connection in the Microsoft Foundry project"
  value       = var.deploy_standard_agent ? azapi_resource.cosmosdb_connection[0].id : null
}

output "account_capability_host_id" {
  description = "ID of the Microsoft Foundry account capability host"
  value       = var.deploy_standard_agent ? azapi_resource.account_capability_host[0].id : null
}

output "account_capability_host_name" {
  description = "Name of the Microsoft Foundry account capability host"
  value       = var.deploy_standard_agent ? azapi_resource.account_capability_host[0].name : null
}

output "project_capability_host_id" {
  description = "ID of the Microsoft Foundry project capability host"
  value       = var.deploy_standard_agent ? azapi_resource.project_capability_host[0].id : null
}

output "project_capability_host_name" {
  description = "Name of the Microsoft Foundry project capability host"
  value       = var.deploy_standard_agent ? azapi_resource.project_capability_host[0].name : null
}
