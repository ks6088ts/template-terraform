resource "azurerm_storage_account" "this" {
  name                            = replace("st${var.name}", "-", "")
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  is_hns_enabled                  = true
  tags                            = var.tags
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_queue" "this" {
  name                 = "st${var.name}-queue"
  storage_account_name = azurerm_storage_account.this.name
}
