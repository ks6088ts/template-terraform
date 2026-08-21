provider "azurerm" {
  features {
    enhanced_validation {
      locations          = true
      resource_providers = true
    }
  }

  resource_provider_registrations = "none"
  resource_providers_to_register = [
    "Microsoft.ApiManagement",
    "Microsoft.CognitiveServices",
    "Microsoft.Resources",
  ]
}

provider "azapi" {
}
