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
  resource_suffix        = module.random_string.result
  resource_name          = "${trim(substr(var.name, 0, 36), "-")}-${local.resource_suffix}"
  microsoft_foundry_name = "aigw${local.resource_suffix}"
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
# Microsoft Foundry
# =============================================================================

module "microsoft_foundry" {
  source = "../../modules/azure/microsoft_foundry"

  name               = local.microsoft_foundry_name
  resource_group_id  = module.resource_group.id
  location           = module.resource_group.location
  tags               = var.tags
  disable_local_auth = true
  model_deployments  = var.model_deployments
}

# =============================================================================
# API Management AI Gateway
# =============================================================================

module "api_management" {
  source = "../../modules/azure/api_management"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  enable_identity     = true
  tags                = var.tags
}

resource "azurerm_role_assignment" "api_management_openai_user" {
  scope                            = module.microsoft_foundry.account_id
  role_definition_name             = "Cognitive Services OpenAI User"
  principal_id                     = module.api_management.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_api_management_backend" "openai" {
  name                = "azure-openai"
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
  protocol            = "http"
  url                 = "${module.microsoft_foundry.openai_endpoint}openai"
  description         = "Microsoft Foundry Azure OpenAI endpoint"
}

resource "azurerm_api_management_api" "openai" {
  name                  = "azure-openai"
  resource_group_name   = module.resource_group.name
  api_management_name   = module.api_management.name
  revision              = "1"
  display_name          = "Azure OpenAI"
  path                  = var.gateway_api_path
  protocols             = ["https"]
  subscription_required = true
}

resource "azurerm_api_management_api_operation" "chat_completions" {
  operation_id        = "chat-completions"
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name
  display_name        = "Create chat completion"
  method              = "POST"
  url_template        = "/deployments/{deployment-id}/chat/completions"
  description         = "Proxy chat completion requests to an Azure OpenAI model deployment."

  template_parameter {
    name     = "deployment-id"
    required = true
    type     = "string"
  }

  response {
    status_code = 200
    description = "Successful chat completion response"
  }
}

resource "azurerm_api_management_product" "ai_gateway" {
  product_id            = "ai-gateway"
  api_management_name   = module.api_management.name
  resource_group_name   = module.resource_group.name
  display_name          = "AI Gateway"
  subscription_required = true
  approval_required     = false
  published             = true
  description           = "Subscription product for Azure OpenAI requests proxied through API Management."
}

resource "azurerm_api_management_product_api" "ai_gateway" {
  api_name            = azurerm_api_management_api.openai.name
  product_id          = azurerm_api_management_product.ai_gateway.product_id
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name
}

resource "azurerm_api_management_api_policy" "openai" {
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <set-query-parameter name="api-version" exists-action="skip">
      <value>${var.openai_api_version}</value>
    </set-query-parameter>
  </inbound>
  <backend>
    <set-backend-service backend-id="${azurerm_api_management_backend.openai.name}" />
    <authentication-managed-identity resource="https://cognitiveservices.azure.com/" />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML

  depends_on = [
    azurerm_role_assignment.api_management_openai_user,
  ]
}
