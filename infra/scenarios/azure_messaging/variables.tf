variable "name" {
  description = "Base name for the messaging resources"
  type        = string
  default     = "azuremessaging"

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 32 && can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])$", var.name))
    error_message = "Name must contain 3 to 32 lowercase letters, numbers, or hyphens and must start and end with a letter or number."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "japaneast"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    scenario        = "azure_messaging"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

variable "operator_principal_id" {
  description = "Optional object ID granted messaging data-plane roles; defaults to the Terraform caller"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.operator_principal_id == null || trimspace(var.operator_principal_id) != ""
    error_message = "Operator principal ID must be null or a non-empty string."
  }
}

variable "enable_queue_storage" {
  description = "Deploy Azure Queue Storage"
  type        = bool
  default     = false
}

variable "enable_service_bus" {
  description = "Deploy Azure Service Bus"
  type        = bool
  default     = false
}

variable "enable_event_grid" {
  description = "Deploy an Azure Event Grid Custom Topic"
  type        = bool
  default     = false
}

variable "enable_event_hubs" {
  description = "Deploy Azure Event Hubs"
  type        = bool
  default     = false
}

variable "queue_storage_replication_type" {
  description = "Replication type for the Standard Queue Storage account"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.queue_storage_replication_type)
    error_message = "Queue Storage replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "service_bus_sku" {
  description = "Service Bus namespace SKU; Standard is the economical default that supports topics"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.service_bus_sku)
    error_message = "Service Bus SKU must be Standard or Premium."
  }
}

variable "service_bus_premium_capacity" {
  description = "Messaging unit capacity used only when the Service Bus SKU is Premium"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 4, 8, 16], var.service_bus_premium_capacity)
    error_message = "Service Bus Premium capacity must be one of: 1, 2, 4, 8, 16."
  }
}

variable "event_grid_input_schema" {
  description = "Schema accepted by the Event Grid Custom Topic"
  type        = string
  default     = "EventGridSchema"

  validation {
    condition     = contains(["EventGridSchema", "CloudEventSchemaV1_0", "CustomEventSchema"], var.event_grid_input_schema)
    error_message = "Event Grid input schema must be EventGridSchema, CloudEventSchemaV1_0, or CustomEventSchema."
  }
}

variable "event_hubs_sku" {
  description = "Event Hubs namespace SKU"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard"], var.event_hubs_sku)
    error_message = "Event Hubs SKU must be Basic or Standard."
  }
}

variable "event_hubs_capacity" {
  description = "Event Hubs namespace throughput unit capacity"
  type        = number
  default     = 1

  validation {
    condition     = var.event_hubs_capacity >= 1 && var.event_hubs_capacity <= 40
    error_message = "Event Hubs capacity must be between 1 and 40."
  }
}

variable "event_hubs_partition_count" {
  description = "Number of partitions in the Event Hub"
  type        = number
  default     = 2

  validation {
    condition     = var.event_hubs_partition_count >= 1 && var.event_hubs_partition_count <= 32
    error_message = "Event Hubs partition count must be between 1 and 32."
  }
}

variable "event_hubs_message_retention" {
  description = "Number of days that Event Hubs retains events; Basic supports one day"
  type        = number
  default     = 1

  validation {
    condition     = var.event_hubs_message_retention >= 1 && var.event_hubs_message_retention <= 7
    error_message = "Event Hubs message retention must be between 1 and 7 days."
  }
}
