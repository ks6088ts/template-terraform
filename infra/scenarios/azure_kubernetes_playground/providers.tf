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
      "Microsoft.Authorization",
      "Microsoft.ContainerRegistry",
      "Microsoft.ContainerService",
      "Microsoft.Resources",
    ],
    var.container_insights_enabled ? [
      "Microsoft.AlertsManagement",
      "Microsoft.Insights",
      "Microsoft.Monitor",
      "Microsoft.OperationalInsights",
    ] : [],
  )
}
