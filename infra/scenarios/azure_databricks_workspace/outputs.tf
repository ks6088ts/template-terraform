output "resource_group_id" {
  description = "Azure Resource Manager ID of the resource group"
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "workspace_resource_id" {
  description = "Azure Resource Manager ID of the workspace"
  value       = module.databricks_workspace.id
}

output "workspace_name" {
  description = "Name of the workspace"
  value       = module.databricks_workspace.name
}

output "workspace_id" {
  description = "Databricks control-plane workspace ID, distinct from workspace_resource_id"
  value       = module.databricks_workspace.workspace_id
}

output "workspace_url" {
  description = "Workspace hostname without a URL scheme"
  value       = module.databricks_workspace.workspace_url
}

output "databricks_host" {
  description = "HTTPS workspace URL with a trailing slash"
  value       = module.databricks_workspace.databricks_host
}

output "managed_resource_group_id" {
  description = "ID of the resource group created and managed by Databricks"
  value       = module.databricks_workspace.managed_resource_group_id
}

output "managed_resource_group_name" {
  description = "Name of the resource group created and managed by Databricks"
  value       = module.databricks_workspace.managed_resource_group_name
}
