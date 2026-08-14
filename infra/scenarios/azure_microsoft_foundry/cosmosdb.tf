resource "azurerm_cosmosdb_account" "agent_threads" {
  count = var.deploy_standard_agent ? 1 : 0

  name                          = "cosmosmsfoundry${local.resource_suffix}"
  location                      = module.resource_group.location
  resource_group_name           = module.resource_group.name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  tags                          = var.tags
  public_network_access_enabled = true
  local_authentication_enabled  = false
  minimal_tls_version           = "Tls12"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = module.resource_group.location
    failover_priority = 0
  }
}