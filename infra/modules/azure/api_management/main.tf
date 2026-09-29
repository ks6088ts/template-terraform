locals {
  identity_type = (
    var.enable_system_assigned_identity && length(var.user_assigned_identity_ids) > 0
    ? "SystemAssigned, UserAssigned"
    : var.enable_system_assigned_identity
    ? "SystemAssigned"
    : length(var.user_assigned_identity_ids) > 0
    ? "UserAssigned"
    : null
  )
}

resource "azurerm_api_management" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  publisher_name                = var.publisher_name
  publisher_email               = var.publisher_email
  sku_name                      = var.sku_name
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_type          = var.virtual_network_type
  tags                          = var.tags

  dynamic "identity" {
    for_each = local.identity_type == null ? [] : [1]
    content {
      type         = local.identity_type
      identity_ids = length(var.user_assigned_identity_ids) > 0 ? var.user_assigned_identity_ids : null
    }
  }

  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_subnet_id == null ? [] : [1]
    content {
      subnet_id = var.virtual_network_subnet_id
    }
  }

  lifecycle {
    precondition {
      condition     = var.virtual_network_type == "None" || var.virtual_network_subnet_id != null
      error_message = "virtual_network_subnet_id is required when virtual_network_type is Internal or External."
    }

    precondition {
      condition     = var.virtual_network_type != "None" || var.virtual_network_subnet_id == null
      error_message = "virtual_network_type must be Internal or External when virtual_network_subnet_id is set."
    }
  }
}
