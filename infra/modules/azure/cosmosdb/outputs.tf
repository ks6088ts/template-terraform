output "account_id" {
  description = "ID of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.id
}

output "account_name" {
  description = "Name of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.name
}

output "account_endpoint" {
  description = "Endpoint of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "primary_key" {
  description = "Primary key of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.primary_key
  sensitive   = true
}

output "sql_database_name" {
  description = "Name of the Cosmos DB SQL database"
  value       = try(azurerm_cosmosdb_sql_database.this[0].name, null)
}

output "sql_database_id" {
  description = "ID of the Cosmos DB SQL database"
  value       = try(azurerm_cosmosdb_sql_database.this[0].id, null)
}

output "sql_container_name" {
  description = "Name of the Cosmos DB SQL container"
  value       = try(azurerm_cosmosdb_sql_container.this[0].name, null)
}

output "sql_container_id" {
  description = "ID of the Cosmos DB SQL container"
  value       = try(azurerm_cosmosdb_sql_container.this[0].id, null)
}
