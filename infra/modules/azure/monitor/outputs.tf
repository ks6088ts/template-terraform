output "id" {
  description = "ID of the Azure Monitor Workspace"
  value       = azurerm_monitor_workspace.this.id
}

output "name" {
  description = "Name of the Azure Monitor Workspace"
  value       = azurerm_monitor_workspace.this.name
}
