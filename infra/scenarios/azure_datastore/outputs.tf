# =============================================================================
# Resource Group
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

# =============================================================================
# Cosmos DB
# =============================================================================

output "cosmosdb_account_id" {
  description = "ID of the Cosmos DB account"
  value       = var.deploy_cosmosdb ? module.cosmosdb[0].account_id : null
}

output "cosmosdb_account_name" {
  description = "Name of the Cosmos DB account"
  value       = var.deploy_cosmosdb ? module.cosmosdb[0].account_name : null
}

output "cosmosdb_account_endpoint" {
  description = "Endpoint of the Cosmos DB account"
  value       = var.deploy_cosmosdb ? module.cosmosdb[0].account_endpoint : null
}

output "cosmosdb_primary_key" {
  description = "Primary key of the Cosmos DB account"
  value       = var.deploy_cosmosdb ? module.cosmosdb[0].primary_key : null
  sensitive   = true
}

output "cosmosdb_sql_database_name" {
  description = "Name of the Cosmos DB SQL database"
  value       = var.deploy_cosmosdb ? module.cosmosdb[0].sql_database_name : null
}

output "cosmosdb_sql_container_name" {
  description = "Name of the Cosmos DB SQL container"
  value       = var.deploy_cosmosdb ? module.cosmosdb[0].sql_container_name : null
}

# =============================================================================
# Storage Account
# =============================================================================

output "storage_account_id" {
  description = "ID of the Storage Account"
  value       = var.deploy_storage_account ? module.storage[0].account_id : null
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = var.deploy_storage_account ? module.storage[0].account_name : null
}

output "storage_account_primary_access_key" {
  description = "Primary access key of the Storage Account"
  value       = var.deploy_storage_account ? module.storage[0].primary_access_key : null
  sensitive   = true
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the Storage Account"
  value       = var.deploy_storage_account ? module.storage[0].primary_blob_endpoint : null
}

output "storage_account_primary_dfs_endpoint" {
  description = "Primary DFS endpoint of the Storage Account (Data Lake Storage)"
  value       = var.deploy_storage_account ? module.storage[0].primary_dfs_endpoint : null
}

output "storage_queue_name" {
  description = "Name of the Storage Queue"
  value       = var.deploy_storage_account ? module.storage[0].queue_name : null
}

# =============================================================================
# Key Vault
# =============================================================================

output "keyvault_id" {
  description = "ID of the Key Vault"
  value       = var.deploy_keyvault ? module.keyvault[0].id : null
}

output "keyvault_name" {
  description = "Name of the Key Vault"
  value       = var.deploy_keyvault ? module.keyvault[0].name : null
}

output "keyvault_uri" {
  description = "URI of the Key Vault"
  value       = var.deploy_keyvault ? module.keyvault[0].uri : null
}

# =============================================================================
# PostgreSQL Flexible Server
# =============================================================================

output "postgresql_server_id" {
  description = "ID of the PostgreSQL Flexible Server"
  value       = var.deploy_postgresql ? module.postgresql[0].server_id : null
}

output "postgresql_server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  value       = var.deploy_postgresql ? module.postgresql[0].server_name : null
}

output "postgresql_server_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server"
  value       = var.deploy_postgresql ? module.postgresql[0].server_fqdn : null
}

output "postgresql_administrator_login" {
  description = "Administrator login of the PostgreSQL Flexible Server"
  value       = var.deploy_postgresql ? module.postgresql[0].administrator_login : null
}

# =============================================================================
# Azure Monitor Workspace
# =============================================================================

output "monitor_workspace_id" {
  description = "ID of the Azure Monitor Workspace"
  value       = var.deploy_monitor_workspace ? module.monitor[0].id : null
}

output "monitor_workspace_name" {
  description = "Name of the Azure Monitor Workspace"
  value       = var.deploy_monitor_workspace ? module.monitor[0].name : null
}
