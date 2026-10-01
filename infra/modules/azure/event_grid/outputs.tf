output "topic_id" {
  description = "ID of the Event Grid topic"
  value       = azurerm_eventgrid_topic.this.id
}

output "topic_name" {
  description = "Name of the Event Grid topic"
  value       = azurerm_eventgrid_topic.this.name
}

output "topic_endpoint" {
  description = "Endpoint of the Event Grid topic"
  value       = azurerm_eventgrid_topic.this.endpoint
}

output "role_assignment_ids" {
  description = "IDs of role assignments created for the Event Grid topic"
  value       = azurerm_role_assignment.event_grid_data_sender[*].id
}
