output "id" {
  description = "ID of the Private Endpoint"
  value       = azurerm_private_endpoint.this.id
}

output "private_ip_address" {
  description = "Private IP address of the service connection"
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
}

output "private_dns_zone_ids" {
  description = "DNS zone IDs associated with the endpoint"
  value       = local.private_dns_zone_ids
}
