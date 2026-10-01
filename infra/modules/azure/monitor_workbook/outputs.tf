output "id" {
  description = "ID of the Workbook"
  value       = azurerm_application_insights_workbook.this.id
}

output "name" {
  description = "Azure resource name of the Workbook"
  value       = azurerm_application_insights_workbook.this.name
}
