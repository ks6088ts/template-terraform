# Container Apps Environment
resource "azurerm_container_app_environment" "this" {
  name                       = "env-${var.name}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  logs_destination           = "log-analytics"
  tags                       = var.tags
}

# Container App
resource "azurerm_container_app" "this" {
  name                         = "app-${var.name}"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode
  tags                         = var.tags

  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : null
    }
  }

  dynamic "registry" {
    for_each = var.registries
    content {
      server   = registry.value.server
      identity = registry.value.identity
    }
  }

  template {
    container {
      name    = "app-${var.name}"
      image   = var.container_image
      cpu     = var.cpu
      memory  = var.memory
      command = length(var.container_command) > 0 ? var.container_command : null

      dynamic "env" {
        for_each = var.env_vars
        content {
          name        = env.value.name
          value       = env.value.secret_name == null ? env.value.value : null
          secret_name = env.value.secret_name
        }
      }

      dynamic "startup_probe" {
        for_each = var.health_probe_path == null ? [] : [var.health_probe_path]
        content {
          transport               = "HTTP"
          port                    = var.target_port
          path                    = startup_probe.value
          initial_delay           = 0
          interval_seconds        = 5
          timeout                 = 3
          failure_count_threshold = 30
        }
      }

      dynamic "liveness_probe" {
        for_each = var.health_probe_path == null ? [] : [var.health_probe_path]
        content {
          transport               = "HTTP"
          port                    = var.target_port
          path                    = liveness_probe.value
          initial_delay           = 10
          interval_seconds        = 30
          timeout                 = 3
          failure_count_threshold = 3
        }
      }

      dynamic "readiness_probe" {
        for_each = var.health_probe_path == null ? [] : [var.health_probe_path]
        content {
          transport               = "HTTP"
          port                    = var.target_port
          path                    = readiness_probe.value
          initial_delay           = 5
          interval_seconds        = 10
          timeout                 = 3
          failure_count_threshold = 3
          success_count_threshold = 1
        }
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  dynamic "ingress" {
    for_each = var.enable_ingress ? [1] : []
    content {
      external_enabled           = var.external_enabled
      allow_insecure_connections = false
      target_port                = var.target_port
      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.min_replicas <= var.max_replicas
      error_message = "min_replicas must be less than or equal to max_replicas."
    }

    precondition {
      condition = contains([
        "0.25:0.5Gi",
        "0.5:1Gi",
        "0.75:1.5Gi",
        "1:2Gi",
        "1.25:2.5Gi",
        "1.5:3Gi",
        "1.75:3.5Gi",
        "2:4Gi",
        "2.25:4.5Gi",
        "2.5:5Gi",
        "2.75:5.5Gi",
        "3:6Gi",
        "3.25:6.5Gi",
        "3.5:7Gi",
        "3.75:7.5Gi",
        "4:8Gi",
      ], "${var.cpu}:${var.memory}")
      error_message = "cpu and memory must use a supported Azure Container Apps Consumption workload combination."
    }

    precondition {
      condition = alltrue([
        for env in var.env_vars : env.secret_name == null || contains(
          [for secret in var.secrets : secret.name],
          env.secret_name,
        )
      ])
      error_message = "Every secret-backed environment variable must reference a name defined in secrets."
    }

    precondition {
      condition     = length(var.registries) == 0 || strcontains(coalesce(var.identity_type, ""), "UserAssigned")
      error_message = "Registry authentication requires a UserAssigned identity_type."
    }

    precondition {
      condition = alltrue([
        for registry in var.registries : contains(var.identity_ids, registry.identity)
      ])
      error_message = "Every registry identity must also be included in identity_ids."
    }
  }
}

# Microsoft Entra ID built-in authentication (Easy Auth)
locals {
  aad_validation_policy = var.authentication == null ? null : merge(
    {
      allowedAudiences = var.authentication.allowed_audiences
    },
    length(var.authentication.allowed_applications) > 0 ? {
      defaultAuthorizationPolicy = {
        allowedApplications = var.authentication.allowed_applications
      }
    } : {}
  )
}

resource "azapi_resource" "auth_config" {
  count = var.authentication == null ? 0 : 1

  type      = "Microsoft.App/containerApps/authConfigs@2025-01-01"
  name      = "current"
  parent_id = azurerm_container_app.this.id

  body = {
    properties = {
      platform = {
        enabled = true
      }
      globalValidation = {
        unauthenticatedClientAction = "Return401"
      }
      httpSettings = {
        requireHttps = true
      }
      identityProviders = {
        azureActiveDirectory = {
          enabled = true
          registration = {
            clientId     = var.authentication.client_id
            openIdIssuer = var.authentication.tenant_auth_endpoint
          }
          validation = local.aad_validation_policy
        }
      }
      login = {
        tokenStore = {
          enabled = false
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.enable_ingress
      error_message = "enable_ingress must be true when authentication is configured."
    }
  }
}
