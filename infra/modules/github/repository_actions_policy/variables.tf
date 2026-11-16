variable "repository" {
  description = "Name of the repository"
  type        = string
}

variable "default_workflow_permissions" {
  description = "Default GITHUB_TOKEN permission for workflows in the repository"
  type        = string
  nullable    = false
  default     = "read"

  validation {
    condition     = contains(["read", "write"], var.default_workflow_permissions)
    error_message = "default_workflow_permissions must be read or write."
  }
}

variable "can_approve_pull_request_reviews" {
  description = "Whether GitHub Actions can approve pull requests"
  type        = bool
  nullable    = false
  default     = false
}

variable "manage_allowed_actions" {
  description = "Manage the repository allowed actions policy. Set false when an organization policy already restricts actions."
  type        = bool
  nullable    = false
  default     = true
}

variable "allowed_actions" {
  description = "Actions allowed to run: all, local_only, or selected"
  type        = string
  nullable    = false
  default     = "selected"

  validation {
    condition     = contains(["all", "local_only", "selected"], var.allowed_actions)
    error_message = "allowed_actions must be all, local_only, or selected."
  }
}

variable "allowed_actions_config" {
  description = "Allow list used when allowed_actions is selected"
  type = object({
    github_owned_allowed = optional(bool, true)
    verified_allowed     = optional(bool, true)
    patterns_allowed     = optional(list(string), [])
  })
  nullable = false
  default  = {}
}

variable "sha_pinning_required" {
  description = "Require actions and reusable workflows to be pinned to a full commit SHA"
  type        = bool
  nullable    = false
  default     = false
}
