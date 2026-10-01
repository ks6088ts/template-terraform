output "namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.this.name
}

output "namespace_fqdn" {
  description = "Fully qualified domain name of the Service Bus namespace"
  value       = "${azurerm_servicebus_namespace.this.name}.servicebus.windows.net"
}

output "queue_id" {
  description = "ID of the Service Bus queue"
  value       = azurerm_servicebus_queue.this.id
}

output "queue_name" {
  description = "Name of the Service Bus queue"
  value       = azurerm_servicebus_queue.this.name
}

output "topic_id" {
  description = "ID of the Service Bus topic"
  value       = azurerm_servicebus_topic.this.id
}

output "topic_name" {
  description = "Name of the Service Bus topic"
  value       = azurerm_servicebus_topic.this.name
}

output "subscription_id" {
  description = "ID of the Service Bus topic subscription"
  value       = azurerm_servicebus_subscription.this.id
}

output "subscription_name" {
  description = "Name of the Service Bus topic subscription"
  value       = azurerm_servicebus_subscription.this.name
}

output "sender_role_assignment_id" {
  description = "ID of the Service Bus data sender role assignment"
  value       = var.operator_principal_id == null ? null : azurerm_role_assignment.data_sender[0].id
}

output "receiver_role_assignment_id" {
  description = "ID of the Service Bus data receiver role assignment"
  value       = var.operator_principal_id == null ? null : azurerm_role_assignment.data_receiver[0].id
}
