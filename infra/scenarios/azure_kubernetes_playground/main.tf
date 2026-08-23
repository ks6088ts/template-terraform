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
  resource_suffix = module.random_string.result
  resource_name   = "${trim(substr(var.name, 0, 40), "-")}-${local.resource_suffix}"
}

# =============================================================================
# Resource Group
# =============================================================================

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = local.resource_name
  location = var.location
  tags     = var.tags
}

# =============================================================================
# Azure Container Registry
# =============================================================================

module "container_registry" {
  source = "../../modules/azure/container_registry"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled
  tags                = var.tags
}

# =============================================================================
# Azure Kubernetes Service
# =============================================================================

module "kubernetes_service" {
  source = "../../modules/azure/kubernetes_service"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  node_resource_group = "rg-aks-${local.resource_name}-nodes"
  location            = module.resource_group.location
  kubernetes_version  = var.kubernetes_version
  oidc_issuer_enabled = var.oidc_issuer_enabled
  vm_size             = var.vm_size
  node_count          = var.node_count
  os_disk_size_gb     = var.os_disk_size_gb
  network_plugin      = var.network_plugin
  enable_acr_pull     = true
  acr_id              = module.container_registry.id
  tags                = var.tags
}
