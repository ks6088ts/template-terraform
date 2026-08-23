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
    "Microsoft.Compute",
    "Microsoft.ContainerRegistry",
    "Microsoft.ContainerService",
    "Microsoft.KeyVault",
    "Microsoft.ManagedIdentity",
    "Microsoft.Network",
    "Microsoft.Resources",
    "Microsoft.Storage",
  ]
}
