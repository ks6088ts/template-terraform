module "cosmosdb" {
  source = "../../modules/azure/cosmosdb"
  count  = var.deploy_standard_agent ? 1 : 0

  name                          = local.resource_name
  account_name                  = "cosmosmsfoundry${local.resource_suffix}"
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tags                          = var.tags
  capabilities                  = []
  public_network_access_enabled = true
  local_authentication_enabled  = false
  minimal_tls_version           = "Tls12"
  consistency_level             = "Session"
  create_sql_database           = false
  create_sql_container          = false
}

moved {
  from = azurerm_cosmosdb_account.agent_threads[0]
  to   = module.cosmosdb[0].azurerm_cosmosdb_account.this
}