variable "name" {
  description = "Name of the Monitor Activity Log Alert"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the alert rule"
  type        = string
}

variable "scopes" {
  description = "Subscription, resource group, or resource IDs monitored by the alert"
  type        = set(string)

  validation {
    condition     = length(var.scopes) > 0
    error_message = "scopes must contain at least one monitored resource ID."
  }
}

variable "resource_group_filter" {
  description = "Name, not resource ID, of the resource group whose Administrative events are monitored"
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_filter)) > 0 && !strcontains(var.resource_group_filter, "/")
    error_message = "resource_group_filter must be a nonempty resource group name, not a resource ID."
  }
}

variable "action_group_ids" {
  description = "Resource IDs of Action Groups notified by the alert"
  type        = set(string)
}

variable "tags" {
  description = "Tags to apply to the Monitor Activity Log Alert"
  type        = map(string)
  default     = {}
}
