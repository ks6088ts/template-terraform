module "storage" {
  count  = var.enable_private_endpoint_example ? 1 : 0
  source = "../../modules/azure/storage"

  name                          = local.resource_name
  storage_account_name          = local.storage_account_name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tags                          = var.tags
  account_tier                  = var.storage_account_tier
  account_replication_type      = var.storage_account_replication_type
  enable_hns                    = false
  public_network_access_enabled = false
  shared_access_key_enabled     = false
  enable_identity               = false
}

module "private_endpoint_blob" {
  count  = var.enable_private_endpoint_example ? 1 : 0
  source = "../../modules/azure/private_endpoint"

  name                           = "blob-${local.resource_name}"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  tags                           = var.tags
  subnet_id                      = module.spoke_virtual_network.subnet_ids["snet-private-endpoints"]
  private_connection_resource_id = module.storage[0].account_id
  subresource_names              = ["blob"]
  private_dns_zone_name          = "privatelink.blob.core.windows.net"
  virtual_network_links = {
    spoke = {
      name               = "link-blob-${local.resource_name}"
      virtual_network_id = module.spoke_virtual_network.vnet_id
    }
  }
}
