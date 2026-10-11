output "id" {
  description = "Azure Resource Manager ID of the workspace"
  value       = azurerm_databricks_workspace.this.id
}

output "name" {
  description = "Name of the workspace"
  value       = azurerm_databricks_workspace.this.name
}

output "location" {
  description = "Azure region of the workspace"
  value       = azurerm_databricks_workspace.this.location
}

output "sku" {
  description = "SKU of the workspace"
  value       = azurerm_databricks_workspace.this.sku
}

output "tags" {
  description = "Tags applied to the workspace"
  value       = azurerm_databricks_workspace.this.tags
}

output "workspace_id" {
  description = "Databricks control-plane workspace ID, distinct from the Azure Resource Manager ID"
  value       = azurerm_databricks_workspace.this.workspace_id
}

output "workspace_url" {
  description = "Workspace hostname without a URL scheme"
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "databricks_host" {
  description = "HTTPS workspace URL with a trailing slash"
  value       = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}

output "managed_resource_group_id" {
  description = "ID of the resource group created and managed by Databricks"
  value       = azurerm_databricks_workspace.this.managed_resource_group_id
}

output "managed_resource_group_name" {
  description = "Name of the resource group created and managed by Databricks"
  value       = azurerm_databricks_workspace.this.managed_resource_group_name
}
