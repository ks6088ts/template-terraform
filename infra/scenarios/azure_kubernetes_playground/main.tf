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
# Azure Container Registry
# =============================================================================

module "container_registry" {
  source = "../../modules/azure/container_registry"

  name                = var.name
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

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  kubernetes_version  = var.kubernetes_version
  vm_size             = var.vm_size
  node_count          = var.node_count
  os_disk_size_gb     = var.os_disk_size_gb
  network_plugin      = var.network_plugin
  enable_acr_pull     = true
  acr_id              = module.container_registry.id
  tags                = var.tags
}
