mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
  }

  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateEndpoints/pe-test"
      private_service_connection = {
        private_ip_address = "10.1.1.4"
      }
    }
  }
}

variables {
  name                           = "blob-test"
  resource_group_name            = "rg-test"
  location                       = "japaneast"
  subnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/spoke/subnets/private-endpoints"
  private_connection_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest"
  subresource_names              = ["blob"]
  private_dns_zone_name          = "privatelink.blob.core.windows.net"
  virtual_network_links = {
    spoke = {
      name               = "link-blob-test"
      virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/spoke"
    }
  }
  tags = { environment = "test" }
}

run "blob_with_new_zone" {
  command = plan

  assert {
    condition = alltrue([
      azurerm_private_endpoint.this.name == "pe-blob-test",
      azurerm_private_endpoint.this.subnet_id == var.subnet_id,
      azurerm_private_endpoint.this.private_service_connection[0].name == "psc-blob-test",
      azurerm_private_endpoint.this.private_service_connection[0].private_connection_resource_id == var.private_connection_resource_id,
      azurerm_private_endpoint.this.private_service_connection[0].subresource_names == tolist(["blob"]),
      !azurerm_private_endpoint.this.private_service_connection[0].is_manual_connection,
      azurerm_private_endpoint.this.private_dns_zone_group[0].name == "pdz-blob-test",
      toset(azurerm_private_endpoint.this.private_dns_zone_group[0].private_dns_zone_ids) == toset(output.private_dns_zone_ids),
      output.private_dns_zone_ids == tolist([azurerm_private_dns_zone.this[0].id]),
      azurerm_private_dns_zone.this[0].name == var.private_dns_zone_name,
      azurerm_private_dns_zone_virtual_network_link.this["spoke"].name == "link-blob-test",
      azurerm_private_dns_zone_virtual_network_link.this["spoke"].private_dns_zone_id == azurerm_private_dns_zone.this[0].id,
      azurerm_private_dns_zone_virtual_network_link.this["spoke"].virtual_network_id == var.virtual_network_links.spoke.virtual_network_id,
      !azurerm_private_dns_zone_virtual_network_link.this["spoke"].registration_enabled,
      azurerm_private_endpoint.this.tags == var.tags,
      azurerm_private_dns_zone.this[0].tags == var.tags,
      azurerm_private_dns_zone_virtual_network_link.this["spoke"].tags == var.tags,
      output.id == azurerm_private_endpoint.this.id,
      output.private_ip_address == "10.1.1.4",
    ])
    error_message = "The Blob endpoint must use the configured names, wiring, tags, DNS registration policy, and outputs."
  }
}

run "key_vault_with_multiple_links" {
  command = plan

  variables {
    name                           = "vault-test"
    private_connection_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/vault-test"
    subresource_names              = ["vault"]
    private_dns_zone_name          = "privatelink.vaultcore.azure.net"
    virtual_network_links = {
      hub = {
        name               = "link-vault-hub"
        virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/hub"
      }
      spoke = {
        name               = "link-vault-spoke"
        virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/spoke"
      }
    }
  }

  assert {
    condition = alltrue([
      azurerm_private_endpoint.this.name == "pe-vault-test",
      azurerm_private_endpoint.this.private_service_connection[0].private_connection_resource_id == var.private_connection_resource_id,
      azurerm_private_endpoint.this.private_service_connection[0].subresource_names == tolist(["vault"]),
      azurerm_private_dns_zone.this[0].name == "privatelink.vaultcore.azure.net",
      length(azurerm_private_dns_zone_virtual_network_link.this) == 2,
      alltrue([for key, link in azurerm_private_dns_zone_virtual_network_link.this :
        link.name == var.virtual_network_links[key].name &&
        link.virtual_network_id == var.virtual_network_links[key].virtual_network_id &&
        !link.registration_enabled
      ]),
    ])
    error_message = "The same module must support Key Vault and multiple VNet links without Blob-specific settings."
  }
}

run "existing_zones" {
  command = plan

  variables {
    create_private_dns_zone = false
    private_dns_zone_name   = null
    virtual_network_links   = {}
    private_dns_zone_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net",
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/example.internal",
    ]
  }

  assert {
    condition = alltrue([
      length(azurerm_private_dns_zone.this) == 0,
      length(azurerm_private_dns_zone_virtual_network_link.this) == 0,
      toset(azurerm_private_endpoint.this.private_dns_zone_group[0].private_dns_zone_ids) == toset(var.private_dns_zone_ids),
      output.private_dns_zone_ids == var.private_dns_zone_ids,
    ])
    error_message = "Existing zones must be used verbatim without creating zones or VNet links."
  }
}

run "new_zone_requires_links" {
  command = plan
  variables {
    virtual_network_links = {}
  }
  expect_failures = [azurerm_private_endpoint.this]
}

run "new_zone_rejects_existing_ids" {
  command = plan
  variables {
    private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
  }
  expect_failures = [azurerm_private_endpoint.this]
}

run "existing_mode_requires_ids" {
  command = plan
  variables {
    create_private_dns_zone = false
    private_dns_zone_name   = null
    virtual_network_links   = {}
  }
  expect_failures = [azurerm_private_endpoint.this]
}

run "existing_mode_rejects_new_zone_configuration" {
  command = plan
  variables {
    create_private_dns_zone = false
    private_dns_zone_ids    = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
  }
  expect_failures = [azurerm_private_endpoint.this]
}

run "empty_subresources" {
  command = plan
  variables {
    subresource_names = []
  }
  expect_failures = [var.subresource_names]
}

run "null_subresource" {
  command = plan
  variables {
    subresource_names = [null]
  }
  expect_failures = [var.subresource_names]
}

run "empty_zone_name" {
  command = plan
  variables {
    private_dns_zone_name = " "
  }
  expect_failures = [var.private_dns_zone_name]
}

run "invalid_link" {
  command = plan
  variables {
    virtual_network_links = {
      spoke = { name = null, virtual_network_id = null }
    }
  }
  expect_failures = [var.virtual_network_links]
}

run "empty_existing_zone_id" {
  command = plan
  variables {
    create_private_dns_zone = false
    private_dns_zone_name   = null
    virtual_network_links   = {}
    private_dns_zone_ids    = [""]
  }
  expect_failures = [var.private_dns_zone_ids]
}

run "empty_target_id" {
  command = plan
  variables {
    private_connection_resource_id = ""
  }
  expect_failures = [var.private_connection_resource_id]
}

run "empty_subnet_id" {
  command = plan
  variables {
    subnet_id = " "
  }
  expect_failures = [var.subnet_id]
}

run "missing_zone_name" {
  command = plan
  variables {
    private_dns_zone_name = null
  }
  expect_failures = [azurerm_private_dns_zone.this]
}
