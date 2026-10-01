resource "azurerm_network_watcher" "this" {
  count = var.create ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

data "azurerm_network_watcher" "this" {
  count = var.create ? 0 : 1

  name                = var.name
  resource_group_name = var.resource_group_name
}
