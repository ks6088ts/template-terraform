# Container Apps Environment
resource "azurerm_container_app_environment" "this" {
  name                       = "env-${var.name}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags
}

# Container App
resource "azurerm_container_app" "this" {
  name                         = "app-${var.name}"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode
  tags                         = var.tags

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : null
    }
  }

  template {
    container {
      name    = "app-${var.name}"
      image   = var.container_image
      cpu     = var.cpu
      memory  = var.memory
      command = length(var.container_command) > 0 ? var.container_command : null
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  dynamic "ingress" {
    for_each = var.enable_ingress ? [1] : []
    content {
      external_enabled = var.external_enabled
      target_port      = var.target_port
      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }
}
