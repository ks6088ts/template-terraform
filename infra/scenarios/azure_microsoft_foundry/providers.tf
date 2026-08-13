provider "azurerm" {
  features {
    enhanced_validation {
      locations          = true
      resource_providers = true
    }
  }

  resource_provider_registrations = "none"
  resource_providers_to_register = concat(
    [
      "Microsoft.CognitiveServices",
      "Microsoft.Resources",
    ],
    var.deploy_azure_ai_search ? ["Microsoft.Search"] : [],
  )
}

provider "azapi" {
}
