variable "name" {
  description = "Base name for observability resources"
  type        = string
  default     = "observability"

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 32 && can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])$", var.name))
    error_message = "Name must contain 3 to 32 lowercase letters, numbers, or hyphens and start and end with a letter or number."
  }
}

variable "location" {
  description = "Azure region for regional resources"
  type        = string
  default     = "japaneast"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "features" {
  description = "Opt-in features; dependencies must be explicitly enabled in this same object"
  type = object({
    azure_monitor        = optional(bool, false)
    log_analytics        = optional(bool, false)
    application_insights = optional(bool, false)
    network_watcher      = optional(bool, false)
    activity_log         = optional(bool, false)
    alert_rules          = optional(bool, false)
    action_group         = optional(bool, false)
    workbook             = optional(bool, false)
  })
  default  = {}
  nullable = false

  validation {
    condition     = !var.features.application_insights || var.features.log_analytics
    error_message = "Application Insights requires features.log_analytics = true."
  }

  validation {
    condition     = !var.features.activity_log || var.features.log_analytics
    error_message = "Activity Log export requires features.log_analytics = true."
  }

  validation {
    condition     = !var.features.workbook || var.features.log_analytics
    error_message = "Workbook requires features.log_analytics = true."
  }

  validation {
    condition     = !var.features.alert_rules || var.features.action_group
    error_message = "Alert rules require features.action_group = true."
  }
}

variable "network_watcher" {
  description = "Reuse the regional Network Watcher by default; create=true creates one in the scenario resource group instead"
  type = object({
    create              = optional(bool, false)
    name                = optional(string)
    resource_group_name = optional(string, "NetworkWatcherRG")
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.network_watcher.name == null ? true : trimspace(var.network_watcher.name) != ""
    error_message = "Network Watcher name must be null or non-empty."
  }

  validation {
    condition     = trimspace(var.network_watcher.resource_group_name) != ""
    error_message = "The existing Network Watcher resource group name must be non-empty."
  }
}

variable "log_analytics_sku" {
  description = "Log Analytics workspace SKU; PerGB2018 avoids a capacity commitment"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_in_days" {
  description = "Log Analytics retention period; 30 days is the economical default"
  type        = number
  default     = 30
}

variable "log_analytics_daily_quota_gb" {
  description = "Daily workspace ingestion cap in GB; -1 disables the cap, which is not a strict spending limit"
  type        = number
  default     = 0.5

  validation {
    condition     = var.log_analytics_daily_quota_gb == -1 || var.log_analytics_daily_quota_gb > 0
    error_message = "The daily quota must be -1 (unlimited) or a positive number of GB."
  }
}

variable "application_insights_sampling_percentage" {
  description = "Application Insights telemetry sampling percentage (0-100)"
  type        = number
  default     = 25

  validation {
    condition     = var.application_insights_sampling_percentage >= 0 && var.application_insights_sampling_percentage <= 100
    error_message = "Application Insights sampling percentage must be between 0 and 100."
  }
}

variable "activity_log_categories" {
  description = "Subscription Activity Log categories exported to Log Analytics"
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
    condition = length(var.activity_log_categories) > 0 && alltrue([
      for category in var.activity_log_categories : contains([
        "Administrative", "Security", "ServiceHealth", "Alert",
        "Recommendation", "Policy", "Autoscale", "ResourceHealth",
      ], category)
    ])
    error_message = "Select at least one supported subscription Activity Log category."
  }
}

variable "action_group_email_addresses" {
  description = "Optional email notification recipients; empty by default"
  type        = set(string)
  default     = []
}
