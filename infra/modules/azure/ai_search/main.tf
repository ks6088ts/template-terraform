resource "azurerm_search_service" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  sku                          = var.sku
  local_authentication_enabled = var.local_authentication_enabled
  tags                         = var.tags

  dynamic "identity" {
    for_each = var.enable_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }
}