output "account_id" {
  description = "ID of the Storage Account"
  value       = azurerm_storage_account.this.id
}

output "account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.this.name
}

output "hns_enabled" {
  description = "Whether hierarchical namespace is enabled"
  value       = azurerm_storage_account.this.is_hns_enabled
}

output "primary_access_key" {
  description = "Primary access key of the Storage Account"
  value       = var.shared_access_key_enabled ? azurerm_storage_account.this.primary_access_key : null
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

output "primary_queue_endpoint" {
  description = "Primary Queue endpoint of the Storage Account"
  value       = azurerm_storage_account.this.primary_queue_endpoint
}

output "queue_name" {
  description = "Name of the Storage Queue"
  value       = var.create_queue ? azurerm_storage_queue.this[0].name : null
}

output "queue_id" {
  description = "ID of the Storage Queue"
  value       = var.create_queue ? azurerm_storage_queue.this[0].id : null
}

output "queue_data_contributor_role_assignment_id" {
  description = "ID of the Queue data contributor role assignment"
  value       = var.create_queue && var.queue_data_contributor_principal_id != null ? azurerm_role_assignment.queue_data_contributor[0].id : null
}

output "container_name" {
  description = "Name of the Storage Container"
  value       = var.create_container ? azurerm_storage_container.this[0].name : null
}

output "container_id" {
  description = "ID of the Storage Container"
  value       = var.create_container ? azurerm_storage_container.this[0].id : null
}
