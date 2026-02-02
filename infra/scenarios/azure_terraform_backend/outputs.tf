output "resource_group_name" {
  value       = module.resource_group.name
  description = "created resource group name"
}

output "storage_account_name" {
  value       = module.storage.account_name
  description = "created storage account name"
}

output "storage_container_name" {
  value       = module.storage.container_name
  description = "created storage container name"
}
