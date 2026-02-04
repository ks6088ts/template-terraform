# =============================================================================
# Azure Functions Flex Consumption Module
# =============================================================================

# Get current client configuration for role assignment
data "azurerm_client_config" "current" {}

# Azure Service Plan (Flex Consumption)
resource "azurerm_service_plan" "this" {
  name                   = "plan-${var.name}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  sku_name               = "FC1"
  os_type                = "Linux"
  zone_balancing_enabled = var.zone_redundant
  tags                   = var.tags
}

# Storage Account for Functions
resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  tags                            = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Storage Container for deployment packages
resource "azurerm_storage_container" "deployment" {
  name                  = var.deployment_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Locals
locals {
  blob_storage_and_container = "${azurerm_storage_account.this.primary_blob_endpoint}${var.deployment_container_name}"
}

# Azure Functions Flex Consumption
resource "azurerm_function_app_flex_consumption" "this" {
  name                        = "func-${var.name}"
  resource_group_name         = var.resource_group_name
  location                    = var.location
  service_plan_id             = azurerm_service_plan.this.id
  storage_container_type      = "blobContainer"
  storage_container_endpoint  = local.blob_storage_and_container
  storage_authentication_type = "SystemAssignedIdentity"
  runtime_name                = var.runtime_name
  runtime_version             = var.runtime_version
  maximum_instance_count      = var.maximum_instance_count
  instance_memory_in_mb       = var.instance_memory_in_mb
  tags                        = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    # Application Insights is optional - skip if not provided
  }

  app_settings = merge(
    {
      # Workaround: https://github.com/hashicorp/terraform-provider-azurerm/pull/29099
      "AzureWebJobsStorage"                  = ""
      "AzureWebJobsStorage__accountName"     = azurerm_storage_account.this.name
      "AzureWebJobsStorage__credential"      = "managedidentity"
      "AzureWebJobsStorage__blobServiceUri"  = azurerm_storage_account.this.primary_blob_endpoint
      "AzureWebJobsStorage__queueServiceUri" = azurerm_storage_account.this.primary_queue_endpoint
      "AzureWebJobsStorage__tableServiceUri" = azurerm_storage_account.this.primary_table_endpoint
    },
    var.app_settings
  )

  depends_on = [
    azurerm_storage_container.deployment
  ]
}

# Role Assignment: Storage Blob Data Owner for Function App
resource "azurerm_role_assignment" "storage_blob_data_owner" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Role Assignment: Storage Queue Data Contributor for Function App
resource "azurerm_role_assignment" "storage_queue_data_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Role Assignment: Storage Table Data Contributor for Function App
resource "azurerm_role_assignment" "storage_table_data_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Role Assignment: Storage Blob Data Contributor for Terraform executor (current client)
# This is needed because shared_access_key_enabled = false, so we need RBAC to upload blobs
resource "azurerm_role_assignment" "storage_blob_data_contributor_terraform" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
