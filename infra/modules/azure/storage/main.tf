resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  is_hns_enabled                  = var.is_hns_enabled
  tags                            = var.tags
  public_network_access_enabled   = var.public_network_access_enabled
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  https_traffic_only_enabled      = var.https_traffic_only_enabled
  min_tls_version                 = var.min_tls_version
  shared_access_key_enabled       = var.shared_access_key_enabled

  dynamic "identity" {
    for_each = var.enable_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "blob_properties" {
    for_each = var.enable_blob_soft_delete ? [1] : []
    content {
      delete_retention_policy {
        days = var.blob_soft_delete_retention_days
      }
      container_delete_retention_policy {
        days = var.container_soft_delete_retention_days
      }
    }
  }
}

resource "azurerm_storage_queue" "this" {
  count              = var.create_queue ? 1 : 0
  name               = "st${var.name}-queue"
  storage_account_id = azurerm_storage_account.this.id
}

resource "azurerm_storage_container" "this" {
  count                 = var.create_container ? 1 : 0
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = var.container_access_type
}

resource "azurerm_private_dns_zone" "blob" {
  count = var.private_endpoint == null ? 0 : (var.private_endpoint.create_private_dns_zone ? 1 : 0)

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count = var.private_endpoint == null ? 0 : (var.private_endpoint.create_private_dns_zone ? 1 : 0)

  name                 = "link-blob-${var.name}"
  private_dns_zone_id  = azurerm_private_dns_zone.blob[0].id
  virtual_network_id   = var.private_endpoint.virtual_network_id
  registration_enabled = false
  tags                 = var.tags
}

resource "azurerm_private_endpoint" "blob" {
  count = var.private_endpoint == null ? 0 : 1

  name                = "pe-blob-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob-${var.name}"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name = "pdz-blob-${var.name}"
    private_dns_zone_ids = [
      var.private_endpoint.create_private_dns_zone
      ? azurerm_private_dns_zone.blob[0].id
      : var.private_endpoint.private_dns_zone_id
    ]
  }
}
