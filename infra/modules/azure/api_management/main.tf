resource "azurerm_api_management" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  tags                = var.tags

  dynamic "identity" {
    for_each = var.enable_system_assigned_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }
}

data "azurerm_api_management" "this" {
  count = var.enable_system_assigned_identity ? 1 : 0

  name                = azurerm_api_management.this.name
  resource_group_name = azurerm_api_management.this.resource_group_name

  depends_on = [azurerm_api_management.this]
}
