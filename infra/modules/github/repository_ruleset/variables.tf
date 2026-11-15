variable "repository" {
  description = "Name of the repository that receives the ruleset"
  type        = string
}

variable "name" {
  description = "Name of the ruleset"
  type        = string
  nullable    = false
  default     = "default-branch-protection"
}

variable "enforcement" {
  description = "Ruleset enforcement: active or disabled (evaluate is organization-only)"
  type        = string
  nullable    = false
  default     = "active"

  validation {
    condition     = contains(["active", "disabled"], var.enforcement)
    error_message = "enforcement must be active or disabled for repository rulesets."
  }
}

variable "ref_name_include" {
  description = "Ref patterns protected by the ruleset (ghqr repo-bp-001 checks the default branch)"
  type        = list(string)
  nullable    = false
  default     = ["~DEFAULT_BRANCH"]
}

variable "ref_name_exclude" {
  description = "Ref patterns excluded from the ruleset"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "bypass_actors" {
  description = "Actors that can bypass the ruleset. RepositoryRole IDs: 1=read, 2=triage, 4=write, 5=admin."
  type = list(object({
    actor_id    = optional(number)
    actor_type  = string
    bypass_mode = optional(string, "pull_request")
  }))
  nullable = false
  default  = []
}

variable "rules" {
  description = "Branch protection rules mapped to ghqr repo-bp-002..013"
  type = object({
    required_approving_review_count      = optional(number, 2)
    dismiss_stale_reviews_on_push        = optional(bool, true)
    require_code_owner_review            = optional(bool, true)
    require_last_push_approval           = optional(bool, true)
    required_review_thread_resolution    = optional(bool, true)
    allowed_merge_methods                = optional(list(string), ["squash", "rebase"])
    required_status_checks               = optional(list(object({ context = string, integration_id = optional(number) })), [])
    strict_required_status_checks_policy = optional(bool, true)
    non_fast_forward                     = optional(bool, true)
    deletion                             = optional(bool, true)
    required_signatures                  = optional(bool, true)
    required_linear_history              = optional(bool, true)
    required_code_scanning = optional(list(object({
      tool                      = optional(string, "CodeQL")
      alerts_threshold          = optional(string, "errors")
      security_alerts_threshold = optional(string, "high_or_higher")
    })), [])
  })
  nullable = false
  default  = {}

  validation {
    condition     = var.rules.required_approving_review_count >= 0 && var.rules.required_approving_review_count <= 10
    error_message = "required_approving_review_count must be between 0 and 10."
  }
}
