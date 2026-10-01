output "resource_group_id" {
  description = "Resource group ARM ID"
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.name
}

output "azure_monitor_id" {
  description = "Azure Monitor workspace ARM ID, or null when disabled"
  value       = var.features.azure_monitor ? module.azure_monitor[0].id : null
}

output "azure_monitor_name" {
  description = "Azure Monitor workspace name, or null when disabled"
  value       = var.features.azure_monitor ? module.azure_monitor[0].name : null
}

output "log_analytics_id" {
  description = "Log Analytics workspace ARM ID, or null when disabled"
  value       = var.features.log_analytics ? module.log_analytics[0].id : null
}

output "log_analytics_name" {
  description = "Log Analytics workspace name, or null when disabled"
  value       = var.features.log_analytics ? module.log_analytics[0].name : null
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace GUID (not its ARM ID), or null when disabled"
  value       = var.features.log_analytics ? module.log_analytics[0].workspace_id : null
}

output "application_insights_id" {
  description = "Application Insights ARM ID, or null when disabled"
  value       = var.features.application_insights ? module.application_insights[0].id : null
}

output "application_insights_name" {
  description = "Application Insights name, or null when disabled"
  value       = var.features.application_insights ? module.application_insights[0].name : null
}

output "network_watcher_id" {
  description = "Created or existing Network Watcher ARM ID, or null when disabled"
  value       = var.features.network_watcher ? module.network_watcher[0].id : null
}

output "network_watcher_name" {
  description = "Created or existing Network Watcher name, or null when disabled"
  value       = var.features.network_watcher ? module.network_watcher[0].name : null
}

output "network_watcher_created" {
  description = "Whether this scenario owns the Network Watcher; false for lookup and null when disabled"
  value       = var.features.network_watcher ? module.network_watcher[0].created : null
}

output "activity_log_id" {
  description = "Subscription Activity Log diagnostic setting ID, or null when disabled"
  value       = var.features.activity_log ? module.activity_log[0].id : null
}

output "activity_log_name" {
  description = "Subscription Activity Log diagnostic setting name, or null when disabled"
  value       = var.features.activity_log ? module.activity_log[0].name : null
}

output "action_group_id" {
  description = "Action Group ARM ID, or null when disabled"
  value       = var.features.action_group ? module.action_group[0].id : null
}

output "action_group_name" {
  description = "Action Group name, or null when disabled"
  value       = var.features.action_group ? module.action_group[0].name : null
}

output "alert_rule_id" {
  description = "Activity Log alert rule ARM ID, or null when disabled"
  value       = var.features.alert_rules ? module.alert_rule[0].id : null
}

output "alert_rule_name" {
  description = "Activity Log alert rule name, or null when disabled"
  value       = var.features.alert_rules ? module.alert_rule[0].name : null
}

output "workbook_id" {
  description = "Workbook ARM ID, or null when disabled"
  value       = var.features.workbook ? module.workbook[0].id : null
}

output "workbook_name" {
  description = "Stable Workbook resource GUID, or null when disabled"
  value       = var.features.workbook ? module.workbook[0].name : null
}
