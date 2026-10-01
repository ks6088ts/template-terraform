variable "name" {
  description = "Globally unique name of the Service Bus namespace"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{4,48}[A-Za-z0-9]$", var.name))
    error_message = "Service Bus namespace name must be 6-50 characters, contain only letters, numbers, and hyphens, start with a letter, and end with a letter or number."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "Resource group name must not be empty."
  }
}

variable "location" {
  description = "Azure region for the Service Bus namespace"
  type        = string

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "Location must not be empty."
  }
}

variable "tags" {
  description = "Tags to apply to the Service Bus namespace"
  type        = map(string)
  default     = {}
}

variable "sku" {
  description = "SKU for the Service Bus namespace"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.sku)
    error_message = "SKU must be Standard or Premium."
  }
}

variable "premium_capacity" {
  description = "Number of messaging units for a Premium Service Bus namespace"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 4, 8, 16], var.premium_capacity)
    error_message = "Premium capacity must be 1, 2, 4, 8, or 16 messaging units."
  }
}

variable "queue_name" {
  description = "Name of the Service Bus queue"
  type        = string

  validation {
    condition     = length(var.queue_name) >= 1 && length(var.queue_name) <= 260 && var.queue_name == trimspace(var.queue_name)
    error_message = "Queue name must be 1-260 characters and must not start or end with whitespace."
  }
}

variable "topic_name" {
  description = "Name of the Service Bus topic"
  type        = string

  validation {
    condition     = length(var.topic_name) >= 1 && length(var.topic_name) <= 260 && var.topic_name == trimspace(var.topic_name)
    error_message = "Topic name must be 1-260 characters and must not start or end with whitespace."
  }
}

variable "subscription_name" {
  description = "Name of the Service Bus topic subscription"
  type        = string

  validation {
    condition     = length(var.subscription_name) >= 1 && length(var.subscription_name) <= 50 && var.subscription_name == trimspace(var.subscription_name)
    error_message = "Subscription name must be 1-50 characters and must not start or end with whitespace."
  }
}

variable "operator_principal_id" {
  description = "Optional principal object ID granted Service Bus data sender and receiver roles"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.operator_principal_id == null || can(regex("^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$", var.operator_principal_id))
    error_message = "Operator principal ID must be null or a valid UUID."
  }
}
