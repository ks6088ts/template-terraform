resource "random_id" "this" {
  byte_length = 4
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name}-${random_id.this.hex}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "this" {
  name                            = "satfstates${random_id.this.hex}"
  location                        = var.location
  tags                            = var.tags
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  # Note: shared_access_key_enabled must be true for Terraform to manage containers
  shared_access_key_enabled = true

  identity {
    type = "SystemAssigned"
  }

  # Enable soft delete for blobs to protect against accidental deletion
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "this" {
  name                  = "tfstates"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
