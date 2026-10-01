variable "name" {
  description = "Name of the Event Grid topic"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Event Grid topic"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Event Grid topic"
  type        = map(string)
  default     = {}
}

variable "input_schema" {
  description = "Schema expected for events published to the Event Grid topic"
  type        = string
  default     = "EventGridSchema"

  validation {
    condition     = contains(["EventGridSchema", "CloudEventSchemaV1_0", "CustomEventSchema"], var.input_schema)
    error_message = "Input schema must be one of: EventGridSchema, CloudEventSchemaV1_0, CustomEventSchema."
  }
}

variable "operator_principal_id" {
  description = "Optional principal object ID granted EventGrid Data Sender on the topic"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.operator_principal_id == null || trimspace(var.operator_principal_id) != ""
    error_message = "Operator principal ID must be null or a non-empty string."
  }
}
