resource "random_id" "this" {
  byte_length = 4
}

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "this" {
  name                            = "tfstates${random_id.this.hex}"
  location                        = var.location
  tags                            = var.tags
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_container" "this" {
  name                  = "tfstates"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
