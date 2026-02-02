output "account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.this.id
}

output "account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "primary_access_key" {
  description = "Primary access key of the storage account"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "private_endpoint_id" {
  description = "ID of the blob private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.blob[0].id : null
}

output "private_endpoint_ip" {
  description = "Private IP address of the blob private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.blob[0].private_service_connection[0].private_ip_address : null
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value       = var.enable_private_endpoint ? azurerm_private_dns_zone.blob[0].id : null
}
