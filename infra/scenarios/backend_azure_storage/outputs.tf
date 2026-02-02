output "resource_group_name" {
  value       = module.resource_group.name
  description = "created resource group name"
}

output "storage_account_name" {
  value       = azurerm_storage_account.this.name
  description = "created storage account name"
}

output "storage_container_name" {
  value       = azurerm_storage_container.this.name
  description = "created storage container name"
}
