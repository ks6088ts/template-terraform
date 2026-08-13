provider "azurerm" {
  features {
    enhanced_validation {
      locations          = true
      resource_providers = true
    }
  }

  resource_provider_registrations = "none"
  resource_providers_to_register = [
    "Microsoft.Authorization",
    "Microsoft.Resources",
    "Microsoft.Storage",
    "Microsoft.Web",
  ]
  storage_use_azuread = true
}
