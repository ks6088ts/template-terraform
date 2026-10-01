output "id" {
  description = "ID of the Network Watcher"
  value       = var.create ? azurerm_network_watcher.this[0].id : data.azurerm_network_watcher.this[0].id
}

output "name" {
  description = "Name of the Network Watcher"
  value       = var.create ? azurerm_network_watcher.this[0].name : data.azurerm_network_watcher.this[0].name
}

output "created" {
  description = "Whether this module manages a newly created Network Watcher"
  value       = var.create
}
