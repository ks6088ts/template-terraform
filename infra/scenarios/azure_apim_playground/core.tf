locals {
  core_api_name             = "playground-core-api"
  core_api_path             = "playground"
  core_api_version          = "v1"
  core_policy_fragment_name = "playground-response-headers"
  core_product_id           = "playground"
}

resource "azurerm_api_management_api_version_set" "core" {
  name                = "playground-core"
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
  display_name        = "APIM Playground Core API"
  versioning_scheme   = "Segment"
}

resource "azurerm_api_management_named_value" "scenario_name" {
  name                = "playground-scenario-name"
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
  display_name        = "playground-scenario-name"
  value               = "azure_apim_playground"
  secret              = false
  tags                = ["playground", "configuration"]
}

resource "azurerm_api_management_policy_fragment" "response_headers" {
  name              = local.core_policy_fragment_name
  api_management_id = module.api_management.id
  description       = "Adds stable playground identification headers to responses"
  format            = "rawxml"
  value             = file("${path.module}/policies/response-headers.xml")

  depends_on = [azurerm_api_management_named_value.scenario_name]
}

resource "azurerm_api_management_api" "core" {
  name                  = local.core_api_name
  resource_group_name   = module.resource_group.name
  api_management_name   = module.api_management.name
  revision              = "1"
  display_name          = "APIM Playground Core API"
  description           = "A self-contained API for testing API Management gateway behavior"
  path                  = local.core_api_path
  protocols             = ["https"]
  subscription_required = true
  version               = local.core_api_version
  version_set_id        = azurerm_api_management_api_version_set.core.id

  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${path.module}/openapi/core.json")
  }
}

resource "azurerm_api_management_api_policy" "core" {
  api_name            = azurerm_api_management_api.core.name
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name
  xml_content = templatefile("${path.module}/policies/core-api.xml.tftpl", {
    rate_limit_calls          = var.core_rate_limit.calls
    rate_limit_renewal_period = var.core_rate_limit.renewal_period_seconds
    response_fragment_id      = azurerm_api_management_policy_fragment.response_headers.name
  })
}

resource "azurerm_api_management_api_operation_policy" "hello" {
  api_name            = azurerm_api_management_api.core.name
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name
  operation_id        = "get-hello"
  xml_content         = file("${path.module}/policies/core-hello.xml")
}

resource "azurerm_api_management_api_operation_policy" "mock" {
  api_name            = azurerm_api_management_api.core.name
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name
  operation_id        = "get-mock"
  xml_content         = file("${path.module}/policies/core-mock.xml")
}

resource "azurerm_api_management_product" "playground" {
  product_id            = local.core_product_id
  resource_group_name   = module.resource_group.name
  api_management_name   = module.api_management.name
  display_name          = "APIM Playground"
  description           = "APIs used by the Azure API Management playground scenario"
  subscription_required = true
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product_api" "core" {
  product_id          = azurerm_api_management_product.playground.product_id
  api_name            = azurerm_api_management_api.core.name
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
}

resource "random_password" "subscription_primary_key" {
  length  = 32
  special = false
}

resource "random_password" "subscription_secondary_key" {
  length  = 32
  special = false
}

resource "azurerm_api_management_subscription" "playground" {
  subscription_id     = "playground-client"
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
  product_id          = azurerm_api_management_product.playground.id
  display_name        = "APIM Playground Client"
  primary_key         = random_password.subscription_primary_key.result
  secondary_key       = random_password.subscription_secondary_key.result
  state               = "active"
  allow_tracing       = true
}
