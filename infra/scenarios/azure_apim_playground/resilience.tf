locals {
  backend_apps = var.backend_pool == null ? {} : {
    primary   = "primary"
    secondary = "secondary"
  }
  circuit_breaker_enabled = try(var.backend_pool.circuit_breaker, null) != null
  resilience_api_name     = "playground-resilience-api"
  resilience_api_path     = "resilience"
  weighted_pool_name      = "playground-weighted-pool"
  failover_pool_name      = "playground-failover-pool"
}

resource "terraform_data" "feature_validation" {
  lifecycle {
    precondition {
      condition     = !local.circuit_breaker_enabled || !startswith(var.sku_name, "Consumption_")
      error_message = "backend_pool.circuit_breaker isn't supported by the API Management Consumption tier. Use Developer_1 or higher."
    }

    precondition {
      condition     = var.llm_token_limit == null || local.ai_enabled
      error_message = "llm_token_limit requires ai_backend."
    }

    precondition {
      condition     = var.llm_token_limit == null || !startswith(var.sku_name, "Consumption_")
      error_message = "llm_token_limit isn't supported by the API Management Consumption tier. Use Developer_1 or higher."
    }

    precondition {
      condition     = var.content_safety == null || local.ai_enabled
      error_message = "content_safety requires ai_backend."
    }

    precondition {
      condition     = var.content_safety == null || !startswith(var.sku_name, "Consumption_")
      error_message = "llm-content-safety isn't supported by the API Management Consumption tier. Use Developer_1 or higher."
    }

    precondition {
      condition     = !local.llm_logging_enabled || local.ai_enabled
      error_message = "observability.llm_logging requires ai_backend."
    }

    precondition {
      condition     = !local.token_metrics_enabled || local.ai_enabled
      error_message = "llm_token_metrics requires ai_backend."
    }

    precondition {
      condition     = !local.token_metrics_enabled || local.observability_enabled
      error_message = "llm_token_metrics requires observability."
    }
  }
}

resource "azurerm_container_app_environment" "backends" {
  count = var.backend_pool == null ? 0 : 1

  name                = "env-apim-${local.resource_suffix}"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

resource "azurerm_container_app" "backend" {
  for_each = local.backend_apps

  name                         = "app-apim-${each.key}-${local.resource_suffix}"
  container_app_environment_id = azurerm_container_app_environment.backends[0].id
  resource_group_name          = module.resource_group.name
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    container {
      name   = "echo"
      image  = var.backend_pool.container_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "DISABLE_REQUEST_LOGS"
        value = "true"
      }
    }

    min_replicas = 0
    max_replicas = 1
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 8080
    transport                  = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

resource "azurerm_api_management_backend" "resilience" {
  for_each = local.backend_apps

  name                = "playground-${each.key}"
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
  protocol            = "http"
  url                 = "https://${azurerm_container_app.backend[each.key].latest_revision_fqdn}"
  description         = "${title(each.key)} backend for APIM load-balancing exercises"

  credentials {
    header = {
      "x-backend-name" = each.key
    }
  }
}

resource "azapi_resource" "weighted_pool" {
  count = var.backend_pool == null ? 0 : 1

  type = (
    var.backend_pool.session_affinity_cookie_name == null
    ? "Microsoft.ApiManagement/service/backends@2024-05-01"
    : "Microsoft.ApiManagement/service/backends@2024-10-01-preview"
  )
  name      = local.weighted_pool_name
  parent_id = module.api_management.id

  body = {
    properties = {
      description = "Weighted pool for APIM playground backends"
      type        = "Pool"
      pool = merge(
        {
          services = [
            {
              id       = azurerm_api_management_backend.resilience["primary"].id
              priority = 1
              weight   = var.backend_pool.primary_weight
            },
            {
              id       = azurerm_api_management_backend.resilience["secondary"].id
              priority = 1
              weight   = var.backend_pool.secondary_weight
            },
          ]
        },
        var.backend_pool.session_affinity_cookie_name == null ? {} : {
          sessionAffinity = {
            sessionId = {
              source = "cookie"
              name   = var.backend_pool.session_affinity_cookie_name
            }
          }
        },
      )
    }
  }

  schema_validation_enabled = true
}

resource "azurerm_api_management_backend" "failing_primary" {
  count = local.circuit_breaker_enabled ? 1 : 0

  name                = "playground-primary-failing"
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
  protocol            = "http"
  url                 = "https://${azurerm_container_app.backend["primary"].latest_revision_fqdn}"
  description         = "Primary backend that returns 503 for deterministic circuit-breaker exercises"

  credentials {
    header = {
      "x-backend-name"             = "primary"
      "x-set-response-status-code" = "503"
    }
  }

  circuit_breaker_rule {
    name                       = "playground-failure-rule"
    trip_duration              = var.backend_pool.circuit_breaker.trip_duration
    accept_retry_after_enabled = var.backend_pool.circuit_breaker.accept_retry_after

    failure_condition {
      count             = var.backend_pool.circuit_breaker.failure_count
      interval_duration = var.backend_pool.circuit_breaker.interval_duration

      status_code_range {
        min = 500
        max = 599
      }
    }
  }

  depends_on = [terraform_data.feature_validation]
}

resource "azapi_resource" "failover_pool" {
  count = local.circuit_breaker_enabled ? 1 : 0

  type      = "Microsoft.ApiManagement/service/backends@2024-05-01"
  name      = local.failover_pool_name
  parent_id = module.api_management.id

  body = {
    properties = {
      description = "Priority pool for APIM circuit-breaker exercises"
      type        = "Pool"
      pool = {
        services = [
          {
            id       = azurerm_api_management_backend.failing_primary[0].id
            priority = 1
            weight   = 1
          },
          {
            id       = azurerm_api_management_backend.resilience["secondary"].id
            priority = 2
            weight   = 1
          },
        ]
      }
    }
  }

  schema_validation_enabled = true
}

resource "azurerm_api_management_api" "resilience" {
  count = var.backend_pool == null ? 0 : 1

  name                  = local.resilience_api_name
  resource_group_name   = module.resource_group.name
  api_management_name   = module.api_management.name
  revision              = "1"
  display_name          = "APIM Playground Resilience API"
  description           = "Exercises weighted backend pools and optional circuit-breaker failover"
  path                  = local.resilience_api_path
  protocols             = ["https"]
  subscription_required = true

  import {
    content_format = "openapi+json"
    content_value  = file("${path.module}/openapi/resilience.json")
  }
}

resource "azurerm_api_management_api_policy" "resilience" {
  count = var.backend_pool == null ? 0 : 1

  api_name            = azurerm_api_management_api.resilience[0].name
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name
  xml_content = templatefile("${path.module}/policies/resilience-api.xml.tftpl", {
    response_fragment_id = azurerm_api_management_policy_fragment.response_headers.name
  })
}

resource "azurerm_api_management_api_operation_policy" "weighted" {
  count = var.backend_pool == null ? 0 : 1

  api_name            = azurerm_api_management_api.resilience[0].name
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name
  operation_id        = "get-weighted"
  xml_content = templatefile("${path.module}/policies/set-backend.xml.tftpl", {
    backend_id = azapi_resource.weighted_pool[0].name
  })
}

resource "azurerm_api_management_api_operation_policy" "failover" {
  count = var.backend_pool == null ? 0 : 1

  api_name            = azurerm_api_management_api.resilience[0].name
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name
  operation_id        = "get-failover"
  xml_content = local.circuit_breaker_enabled ? templatefile("${path.module}/policies/set-backend.xml.tftpl", {
    backend_id = azapi_resource.failover_pool[0].name
  }) : file("${path.module}/policies/failover-disabled.xml")
}

resource "azurerm_api_management_product_api" "resilience" {
  count = var.backend_pool == null ? 0 : 1

  product_id          = azurerm_api_management_product.playground.product_id
  api_name            = azurerm_api_management_api.resilience[0].name
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
}
