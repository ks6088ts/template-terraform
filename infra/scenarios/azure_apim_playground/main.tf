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
# API Management
# =============================================================================

module "api_management" {
  source = "../../modules/azure/api_management"

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  tags                = var.tags
}
