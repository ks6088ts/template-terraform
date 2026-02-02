# =============================================================================
# Random String
# =============================================================================

module "random_string" {
  source = "../../modules/common/random_string"

  length      = 8
  min_numeric = 0
  numeric     = true
  special     = false
  lower       = true
  upper       = false
}

# =============================================================================
# Resource Group
# =============================================================================

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = var.name
  location = var.location
  tags     = var.tags
}

# =============================================================================
# Storage Account for Terraform State
# =============================================================================

module "storage" {
  source = "../../modules/azure/storage"

  name                                 = var.name
  storage_account_name                 = "satfstates${module.random_string.result}"
  resource_group_name                  = module.resource_group.name
  location                             = var.location
  tags                                 = var.tags
  account_tier                         = "Standard"
  account_replication_type             = "LRS"
  is_hns_enabled                       = false
  public_network_access_enabled        = true
  allow_nested_items_to_be_public      = false
  https_traffic_only_enabled           = true
  min_tls_version                      = "TLS1_2"
  shared_access_key_enabled            = true
  enable_blob_soft_delete              = true
  blob_soft_delete_retention_days      = 7
  container_soft_delete_retention_days = 7
  create_queue                         = false
  create_container                     = true
  container_name                       = "tfstates"
  container_access_type                = "private"
}
