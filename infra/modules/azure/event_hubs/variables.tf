variable "name" {
  description = "Globally unique name of the Event Hubs namespace"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Event Hubs namespace"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Event Hubs namespace"
  type        = map(string)
  default     = {}
}

variable "sku" {
  description = "SKU for the Event Hubs namespace"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "SKU must be Basic or Standard."
  }
}

variable "capacity" {
  description = "Number of throughput units for the Event Hubs namespace"
  type        = number
  default     = 1

  validation {
    condition     = var.capacity >= 1 && var.capacity <= 40 && floor(var.capacity) == var.capacity
    error_message = "Capacity must be a whole number between 1 and 40."
  }
}

variable "eventhub_name" {
  description = "Name of the event hub"
  type        = string
}

variable "partition_count" {
  description = "Number of partitions for the event hub"
  type        = number
  default     = 2

  validation {
    condition     = var.partition_count >= 1 && var.partition_count <= 32 && floor(var.partition_count) == var.partition_count
    error_message = "Partition count must be a whole number between 1 and 32."
  }
}

variable "message_retention" {
  description = "Number of days to retain events"
  type        = number
  default     = 1

  validation {
    condition     = var.message_retention >= 1 && var.message_retention <= 7 && floor(var.message_retention) == var.message_retention
    error_message = "Message retention must be a whole number between 1 and 7 days."
  }
}

variable "operator_principal_id" {
  description = "Optional principal object ID granted Event Hubs data sender and receiver roles"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.operator_principal_id == null || trimspace(var.operator_principal_id) != ""
    error_message = "Operator principal ID must be null or a non-empty string."
  }
}
