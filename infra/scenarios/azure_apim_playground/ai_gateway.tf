data "azurerm_client_config" "current" {}

locals {
  ai_provision_config = try(var.ai_backend.provision, null)
  ai_existing_config  = try(var.ai_backend.existing, null)
  ai_enabled          = var.ai_backend != null
  ai_provisioned      = local.ai_provision_config != null
  ai_reasoning_effort = try(var.ai_backend.reasoning_effort, null)

  ai_resource_id = local.ai_provisioned ? module.ai_foundry[0].account_id : try(local.ai_existing_config.resource_id, null)
  ai_backend_url = local.ai_provisioned ? "${trimsuffix(module.ai_foundry[0].openai_endpoint, "/")}/openai/v1" : try(
    trimsuffix(local.ai_existing_config.endpoint, "/"),
    null,
  )
  ai_deployment_name = local.ai_provisioned ? try(local.ai_provision_config.deployment_name, null) : try(
    local.ai_existing_config.deployment_name,
    null,
  )
  operator_principal_id = coalesce(var.operator_principal_id, data.azurerm_client_config.current.object_id)

  llm_token_limit_attributes = var.llm_token_limit == null ? [] : concat(
    [
      "counter-key=\"@(context.Subscription.Id)\"",
      "estimate-prompt-tokens=\"${var.llm_token_limit.estimate_prompt_tokens}\"",
      "tokens-consumed-header-name=\"x-llm-tokens-consumed\"",
    ],
    var.llm_token_limit.tokens_per_minute == null ? [] : [
      "tokens-per-minute=\"${var.llm_token_limit.tokens_per_minute}\"",
      "remaining-tokens-header-name=\"x-llm-remaining-tokens\"",
      "retry-after-header-name=\"x-llm-retry-after\"",
    ],
    var.llm_token_limit.token_quota == null ? [] : [
      "token-quota=\"${var.llm_token_limit.token_quota}\"",
      "token-quota-period=\"${var.llm_token_limit.token_quota_period}\"",
      "remaining-quota-tokens-header-name=\"x-llm-remaining-quota-tokens\"",
    ],
  )
  llm_token_limit_policy = var.llm_token_limit == null ? "" : format(
    "<llm-token-limit %s />",
    join(" ", local.llm_token_limit_attributes),
  )
}

module "ai_foundry" {
  count  = local.ai_provisioned ? 1 : 0
  source = "../../modules/azure/microsoft_foundry"

  name                 = "aifoundry${local.resource_suffix}"
  resource_group_id    = module.resource_group.id
  location             = module.resource_group.location
  disable_local_auth   = true
  project_display_name = "APIM Playground"
  project_description  = "Model deployment used by the Azure API Management playground"
  model_deployments = [
    {
      format   = local.ai_provision_config.format
      name     = local.ai_provision_config.deployment_name
      model    = local.ai_provision_config.model
      version  = local.ai_provision_config.version
      sku_name = local.ai_provision_config.sku_name
      capacity = local.ai_provision_config.capacity
    },
  ]
  tags = var.tags
}

resource "azurerm_role_assignment" "apim_ai_user" {
  count = local.ai_enabled ? 1 : 0

  scope                            = local.ai_resource_id
  role_definition_name             = "Cognitive Services User"
  principal_id                     = module.api_management.identity_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_api_management_backend" "ai" {
  count = local.ai_enabled ? 1 : 0

  name                = "playground-ai"
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
  protocol            = "http"
  url                 = local.ai_backend_url
  description         = "OpenAI v1-compatible backend secured with the API Management managed identity"
}

resource "azurerm_api_management_api" "ai" {
  count = local.ai_enabled ? 1 : 0

  name                  = "playground-ai-api"
  resource_group_name   = module.resource_group.name
  api_management_name   = module.api_management.name
  revision              = "1"
  display_name          = "APIM Playground AI API"
  description           = "OpenAI v1-compatible AI gateway API"
  path                  = "ai/openai/v1"
  protocols             = ["https"]
  subscription_required = true

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${path.module}/openapi/openai-v1.json")
  }
}

resource "azurerm_api_management_api_policy" "ai" {
  count = local.ai_enabled ? 1 : 0

  api_name            = azurerm_api_management_api.ai[0].name
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name
  xml_content = templatefile("${path.module}/policies/ai-api.xml.tftpl", {
    backend_id            = azurerm_api_management_backend.ai[0].name
    content_safety_policy = local.content_safety_policy
    token_limit_policy    = local.llm_token_limit_policy
    token_metric_policy   = local.llm_token_metric_policy
    response_fragment_id  = azurerm_api_management_policy_fragment.response_headers.name
  })

  depends_on = [
    azurerm_role_assignment.apim_ai_user,
    azurerm_role_assignment.apim_content_safety_user,
    azapi_resource.content_safety_backend,
  ]
}

resource "azurerm_api_management_product_api" "ai" {
  count = local.ai_enabled ? 1 : 0

  product_id          = azurerm_api_management_product.playground.product_id
  api_name            = azurerm_api_management_api.ai[0].name
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
}
