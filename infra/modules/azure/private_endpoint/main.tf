locals {
  private_dns_zone_ids = var.create_private_dns_zone ? [azurerm_private_dns_zone.this[0].id] : var.private_dns_zone_ids
}

resource "azurerm_private_dns_zone" "this" {
  count = var.create_private_dns_zone ? 1 : 0

  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = var.private_dns_zone_name != null
      error_message = "Private DNS zone name is required when create_private_dns_zone is true."
    }
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.create_private_dns_zone ? var.virtual_network_links : {}

  name                 = each.value.name
  private_dns_zone_id  = azurerm_private_dns_zone.this[0].id
  virtual_network_id   = each.value.virtual_network_id
  registration_enabled = false
  tags                 = var.tags
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = var.private_connection_resource_id
    is_manual_connection           = false
    subresource_names              = var.subresource_names
  }

  private_dns_zone_group {
    name                 = "pdz-${var.name}"
    private_dns_zone_ids = local.private_dns_zone_ids
  }

  lifecycle {
    precondition {
      condition = var.create_private_dns_zone ? (
        length(var.virtual_network_links) > 0 &&
        length(var.private_dns_zone_ids) == 0
        ) : (
        var.private_dns_zone_name == null &&
        length(var.virtual_network_links) == 0 &&
        length(var.private_dns_zone_ids) > 0
      )
      error_message = "Create mode requires private_dns_zone_name and virtual_network_links, without private_dns_zone_ids. Existing mode requires private_dns_zone_ids, without private_dns_zone_name or virtual_network_links."
    }
  }
}
