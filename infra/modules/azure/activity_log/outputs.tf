output "id" {
  description = "ID of the subscription Activity Log diagnostic setting"
  value       = azurerm_monitor_diagnostic_setting.this.id
}

output "name" {
  description = "Name of the subscription Activity Log diagnostic setting"
  value       = azurerm_monitor_diagnostic_setting.this.name
}
