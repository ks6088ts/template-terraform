resource "azurerm_key_vault" "this" {
  name                          = "kv-${var.name}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = var.sku_name
  purge_protection_enabled      = false
  tags                          = var.tags
  public_network_access_enabled = true

  # Allow current user to manage secrets
  access_policy {
    tenant_id = var.tenant_id
    object_id = var.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
    ]

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Purge",
    ]

    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Purge",
    ]
  }
}
