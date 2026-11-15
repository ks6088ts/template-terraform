variable "organization" {
  description = "Login (slug) of the GitHub organization"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]*$", var.organization))
    error_message = "organization must be a GitHub organization login."
  }
}

variable "billing_email" {
  description = "Billing email address of the organization (required by github_organization_settings)"
  type        = string
  default     = null
}

variable "enable_security_defaults" {
  description = "Manage organization settings and security defaults for new repositories. Overwrites every organization setting."
  type        = bool
  default     = true
}

variable "security_defaults" {
  description = "Organization settings passed to the organization_security_defaults module. null attributes use the module defaults."
  type = object({
    default_repository_permission                                = optional(string)
    members_can_create_repositories                              = optional(bool)
    members_can_create_public_repositories                       = optional(bool)
    members_can_create_private_repositories                      = optional(bool)
    members_can_create_public_pages                              = optional(bool)
    members_can_fork_private_repositories                        = optional(bool)
    web_commit_signoff_required                                  = optional(bool)
    advanced_security_enabled_for_new_repositories               = optional(bool)
    dependabot_alerts_enabled_for_new_repositories               = optional(bool)
    dependabot_security_updates_enabled_for_new_repositories     = optional(bool)
    dependency_graph_enabled_for_new_repositories                = optional(bool)
    secret_scanning_enabled_for_new_repositories                 = optional(bool)
    secret_scanning_push_protection_enabled_for_new_repositories = optional(bool)
  })
  default = {}

  validation {
    condition     = contains(["none", "read", "write"], coalesce(var.security_defaults.default_repository_permission, "read"))
    error_message = "default_repository_permission must be none, read, or write (ghqr org-sec-003 flags admin)."
  }
}

variable "enable_actions_policy" {
  description = "Manage the organization GitHub Actions policy"
  type        = bool
  default     = true
}

variable "actions_policy" {
  description = "GitHub Actions policy passed to the organization_actions_policy module. null attributes use the module defaults."
  type = object({
    default_workflow_permissions     = optional(string)
    can_approve_pull_request_reviews = optional(bool)
    allowed_actions                  = optional(string)
    patterns_allowed                 = optional(list(string), [])
    verified_allowed                 = optional(bool, true)
    sha_pinning_required             = optional(bool)
  })
  default = {}
}

variable "security_manager_team" {
  description = "Team that receives the security manager role (ghqr org-sec-005). null skips the assignment."
  type = object({
    slug        = string
    create      = optional(bool, false)
    description = optional(string)
  })
  default = null
}

variable "enable_organization_ruleset" {
  description = "Create an organization ruleset that protects the default branch of matching repositories. Requires GitHub Team or Enterprise."
  type        = bool
  default     = false
}

variable "organization_ruleset" {
  description = "Organization ruleset settings. null attributes in rules use the module defaults."
  type = object({
    name                    = optional(string)
    enforcement             = optional(string)
    repository_name_include = optional(list(string))
    repository_name_exclude = optional(list(string))
    bypass_actors = optional(list(object({
      actor_id    = optional(number)
      actor_type  = string
      bypass_mode = optional(string)
    })), [])
    rules = optional(object({
      required_approving_review_count      = optional(number)
      dismiss_stale_reviews_on_push        = optional(bool)
      require_code_owner_review            = optional(bool)
      require_last_push_approval           = optional(bool)
      required_review_thread_resolution    = optional(bool)
      allowed_merge_methods                = optional(list(string))
      required_status_checks               = optional(list(object({ context = string, integration_id = optional(number) })))
      strict_required_status_checks_policy = optional(bool)
      non_fast_forward                     = optional(bool)
      deletion                             = optional(bool)
      required_signatures                  = optional(bool)
      required_linear_history              = optional(bool)
      required_code_scanning = optional(list(object({
        tool                      = optional(string)
        alerts_threshold          = optional(string)
        security_alerts_threshold = optional(string)
      })))
    }), {})
  })
  default = {}
}
