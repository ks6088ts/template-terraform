variable "organization_slug" {
  description = "Login (slug) of the GitHub organization"
  type        = string
}

variable "default_workflow_permissions" {
  description = "Default GITHUB_TOKEN permission for workflows (ghqr org-act-001)"
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

variable "enabled_repositories" {
  description = "Repositories that can run GitHub Actions: all, none, or selected"
  type        = string
  nullable    = false
  default     = "all"

  validation {
    condition     = contains(["all", "none", "selected"], var.enabled_repositories)
    error_message = "enabled_repositories must be all, none, or selected."
  }
}

variable "enabled_repository_ids" {
  description = "Repository IDs allowed to run GitHub Actions when enabled_repositories is selected"
  type        = list(number)
  nullable    = false
  default     = []
}

variable "allowed_actions" {
  description = "Actions allowed to run: all, local_only, or selected (ghqr org-act-002 flags all, org-act-003 flags local_only)"
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
