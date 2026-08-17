resource "azurerm_container_registry" "this" {
  name                          = "cr${replace(var.name, "-", "")}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  lifecycle {
    precondition {
      condition     = !var.anonymous_pull_enabled || contains(["Standard", "Premium"], var.sku)
      error_message = "Anonymous pull access requires the Standard or Premium SKU."
    }

    precondition {
      condition     = !var.anonymous_pull_enabled || var.public_network_access_enabled
      error_message = "Anonymous pull access requires public network access to be enabled."
    }
  }
}
