# Storage Account with Private Endpoint
resource "azurerm_storage_account" "this" {
  name                          = substr("sa${replace(var.name, "-", "")}${substr(md5(var.resource_group_id), 0, 8)}", 0, 24)
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = var.account_tier
  account_replication_type      = var.account_replication_type
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  dynamic "identity" {
    for_each = var.enable_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }
}

# Private DNS Zone for Blob Storage
resource "azurerm_private_dns_zone" "blob" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count                 = var.enable_private_endpoint ? 1 : 0
  name                  = "link-blob-${var.name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

# Private Endpoint for Blob Storage
resource "azurerm_private_endpoint" "blob" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-blob-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob-${var.name}"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pdz-blob-${var.name}"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }
}
