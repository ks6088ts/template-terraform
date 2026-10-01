variable "name" {
  description = "Name of the subscription Activity Log diagnostic setting"
  type        = string
}

variable "subscription_id" {
  description = "UUID of the subscription whose Activity Log is exported"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a UUID, not a subscription resource ID."
  }
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the destination Log Analytics Workspace"
  type        = string
}

variable "categories" {
  description = "Subscription Activity Log categories to export"
  type        = set(string)
  default = [
    "Administrative",
    "Security",
    "ServiceHealth",
    "Alert",
    "Recommendation",
    "Policy",
    "Autoscale",
    "ResourceHealth",
  ]

  validation {
    condition = length(var.categories) > 0 && alltrue([
      for category in var.categories : contains([
        "Administrative", "Security", "ServiceHealth", "Alert",
        "Recommendation", "Policy", "Autoscale", "ResourceHealth",
      ], category)
    ])
    error_message = "categories must contain at least one supported subscription Activity Log category."
  }
}
