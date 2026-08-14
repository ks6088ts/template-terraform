provider "azurerm" {
  features {
    enhanced_validation {
      locations          = true
      resource_providers = true
    }
  }

  storage_use_azuread = true

  resource_provider_registrations = "none"
  resource_providers_to_register = concat(
    [
      "Microsoft.CognitiveServices",
      "Microsoft.Resources",
    ],
    var.deploy_standard_agent ? [
      "Microsoft.DocumentDB",
      "Microsoft.Search",
      "Microsoft.Storage",
    ] : [],
  )
}

provider "azapi" {
}
