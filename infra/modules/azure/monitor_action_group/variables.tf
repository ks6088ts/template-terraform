variable "name" {
  description = "Name of the Monitor Action Group"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "short_name" {
  description = "Short name used in notifications, with a maximum of 12 characters"
  type        = string
  default     = "observe"

  validation {
    condition     = length(var.short_name) >= 1 && length(var.short_name) <= 12
    error_message = "short_name must contain between 1 and 12 characters."
  }
}

variable "email_addresses" {
  description = "Email addresses that receive alerts using the common alert schema"
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for email in var.email_addresses : can(regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", email))])
    error_message = "email_addresses must contain valid email addresses."
  }
}

variable "tags" {
  description = "Tags to apply to the Monitor Action Group"
  type        = map(string)
  default     = {}
}
