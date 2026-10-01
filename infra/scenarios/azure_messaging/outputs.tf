output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "operator_principal_id" {
  description = "Object ID granted messaging data-plane roles"
  value       = local.operator_principal_id
}

output "queue_storage_account_id" {
  description = "ID of the Queue Storage account"
  value       = var.enable_queue_storage ? module.queue_storage[0].account_id : null
}

output "queue_storage_account_name" {
  description = "Name of the Queue Storage account"
  value       = var.enable_queue_storage ? module.queue_storage[0].account_name : null
}

output "queue_storage_hns_enabled" {
  description = "Whether hierarchical namespace is enabled on the Queue Storage account"
  value       = var.enable_queue_storage ? module.queue_storage[0].hns_enabled : null
}

output "queue_storage_dfs_endpoint" {
  description = "Data Lake Storage Gen2 DFS endpoint"
  value       = var.enable_queue_storage ? module.queue_storage[0].primary_dfs_endpoint : null
}

output "queue_storage_endpoint" {
  description = "Queue service endpoint"
  value       = var.enable_queue_storage ? module.queue_storage[0].primary_queue_endpoint : null
}

output "queue_storage_queue_id" {
  description = "ID of the Storage Queue"
  value       = var.enable_queue_storage ? module.queue_storage[0].queue_id : null
}

output "queue_storage_queue_name" {
  description = "Name of the Storage Queue"
  value       = var.enable_queue_storage ? module.queue_storage[0].queue_name : null
}

output "service_bus_namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = var.enable_service_bus ? module.service_bus[0].namespace_id : null
}

output "service_bus_namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = var.enable_service_bus ? module.service_bus[0].namespace_name : null
}

output "service_bus_namespace_fqdn" {
  description = "Fully qualified domain name of the Service Bus namespace"
  value       = var.enable_service_bus ? module.service_bus[0].namespace_fqdn : null
}

output "service_bus_queue_name" {
  description = "Name of the Service Bus queue"
  value       = var.enable_service_bus ? module.service_bus[0].queue_name : null
}

output "service_bus_topic_name" {
  description = "Name of the Service Bus topic"
  value       = var.enable_service_bus ? module.service_bus[0].topic_name : null
}

output "service_bus_subscription_name" {
  description = "Name of the Service Bus subscription"
  value       = var.enable_service_bus ? module.service_bus[0].subscription_name : null
}

output "event_grid_topic_id" {
  description = "ID of the Event Grid Custom Topic"
  value       = var.enable_event_grid ? module.event_grid[0].topic_id : null
}

output "event_grid_topic_name" {
  description = "Name of the Event Grid Custom Topic"
  value       = var.enable_event_grid ? module.event_grid[0].topic_name : null
}

output "event_grid_topic_endpoint" {
  description = "Endpoint of the Event Grid Custom Topic"
  value       = var.enable_event_grid ? module.event_grid[0].topic_endpoint : null
}

output "event_hubs_namespace_id" {
  description = "ID of the Event Hubs namespace"
  value       = var.enable_event_hubs ? module.event_hubs[0].namespace_id : null
}

output "event_hubs_namespace_name" {
  description = "Name of the Event Hubs namespace"
  value       = var.enable_event_hubs ? module.event_hubs[0].namespace_name : null
}

output "event_hubs_namespace_fqdn" {
  description = "Fully qualified domain name of the Event Hubs namespace"
  value       = var.enable_event_hubs ? module.event_hubs[0].namespace_fqdn : null
}

output "event_hub_id" {
  description = "ID of the Event Hub"
  value       = var.enable_event_hubs ? module.event_hubs[0].eventhub_id : null
}

output "event_hub_name" {
  description = "Name of the Event Hub"
  value       = var.enable_event_hubs ? module.event_hubs[0].eventhub_name : null
}

output "event_hub_consumer_group_name" {
  description = "Name of the built-in Event Hubs consumer group"
  value       = var.enable_event_hubs ? module.event_hubs[0].consumer_group_name : null
}
