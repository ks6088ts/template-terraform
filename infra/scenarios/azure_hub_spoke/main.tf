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
  resource_suffix      = module.random_string.result
  resource_name        = "${trim(substr(var.name, 0, 35), "-")}-${local.resource_suffix}"
  storage_account_name = "sa${substr(replace(var.name, "-", ""), 0, 12)}${local.resource_suffix}"
}

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = local.resource_name
  location = var.location
  tags     = var.tags
}
