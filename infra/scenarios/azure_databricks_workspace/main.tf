module "random_string" {
  source = "../../modules/common/random_string"

  length      = 8
  min_numeric = 0
  numeric     = true
  special     = false
  lower       = true
  upper       = false
}

locals {
  resource_name = "${var.name}-${module.random_string.result}"
}

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = local.resource_name
  location = var.location
  tags     = var.tags
}

module "databricks_workspace" {
  source = "../../modules/azure/databricks_workspace"

  name                        = "dbw-${local.resource_name}"
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  sku                         = var.sku
  managed_resource_group_name = "${module.resource_group.name}-managed"
  tags                        = var.tags
}
