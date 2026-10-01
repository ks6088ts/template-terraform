variable "name" {
  description = "Exact Azure name of the Network Watcher to create or look up"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the Network Watcher"
  type        = string
}

variable "location" {
  description = "Azure region for a newly created Network Watcher"
  type        = string
}

variable "tags" {
  description = "Tags to apply to a newly created Network Watcher"
  type        = map(string)
  default     = {}
}

variable "create" {
  description = "Create a Network Watcher instead of looking up an existing one"
  type        = bool
  default     = false
}
