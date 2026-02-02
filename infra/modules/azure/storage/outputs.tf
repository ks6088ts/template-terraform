output "account_id" {
  description = "ID of the Storage Account"
  value       = azurerm_storage_account.this.id
}

output "account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.this.name
}

output "primary_access_key" {
  description = "Primary access key of the Storage Account"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint of the Storage Account"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary DFS endpoint of the Storage Account (Data Lake Storage)"
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "queue_name" {
  description = "Name of the Storage Queue"
  value       = azurerm_storage_queue.this.name
}
