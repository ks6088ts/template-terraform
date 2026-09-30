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
    var.enable_standard_setup ? [
      "Microsoft.DocumentDB",
      "Microsoft.Search",
      "Microsoft.Storage",
    ] : [],
    var.enable_tracing ? [
      "Microsoft.Insights",
      "Microsoft.OperationalInsights",
    ] : [],
  )
}

provider "azapi" {
}
