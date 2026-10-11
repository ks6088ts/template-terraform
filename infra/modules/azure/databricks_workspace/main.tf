resource "azurerm_databricks_workspace" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  managed_resource_group_name   = var.managed_resource_group_name
  public_network_access_enabled = true
  tags                          = var.tags

  custom_parameters {
    no_public_ip = true
  }
}
