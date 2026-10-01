output "namespace_id" {
  description = "ID of the Event Hubs namespace"
  value       = azurerm_eventhub_namespace.this.id
}

output "namespace_name" {
  description = "Name of the Event Hubs namespace"
  value       = azurerm_eventhub_namespace.this.name
}

output "namespace_fqdn" {
  description = "Fully qualified domain name of the Event Hubs namespace"
  value       = "${azurerm_eventhub_namespace.this.name}.servicebus.windows.net"
}

output "eventhub_id" {
  description = "ID of the event hub"
  value       = azurerm_eventhub.this.id
}

output "eventhub_name" {
  description = "Name of the event hub"
  value       = azurerm_eventhub.this.name
}

output "partition_ids" {
  description = "Partition IDs of the event hub"
  value       = azurerm_eventhub.this.partition_ids
}

output "consumer_group_name" {
  description = "Name of the built-in default consumer group"
  value       = "$Default"
}

output "sender_role_assignment_id" {
  description = "ID of the Event Hubs data sender role assignment"
  value       = var.operator_principal_id == null ? null : azurerm_role_assignment.data_sender[0].id
}

output "receiver_role_assignment_id" {
  description = "ID of the Event Hubs data receiver role assignment"
  value       = var.operator_principal_id == null ? null : azurerm_role_assignment.data_receiver[0].id
}
