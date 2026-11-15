variable "github_owner" {
  description = "GitHub owner (user or organization) of the repositories"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]*$", var.github_owner))
    error_message = "github_owner must be a GitHub user or organization login."
  }
}

variable "repositories" {
  description = "Repositories to harden, keyed by repository name. null attributes use the module defaults."
  type = map(object({
    # true: create the repository with Terraform. false: harden an existing repository without managing github_repository.
    create_repository = optional(bool, true)
    default_branch    = optional(string, "main")

    # github_repository settings (create_repository = true only)
    description     = optional(string, "Repository hardened with the ghqr security baseline")
    visibility      = optional(string)
    topics          = optional(list(string), ["security", "terraform"])
    has_issues      = optional(bool)
    has_discussions = optional(bool)
    # false leaves security and analysis unmanaged (for example private repositories without GHAS licenses).
    manage_security_and_analysis = optional(bool, true)
    security_and_analysis = optional(object({
      advanced_security                     = optional(string)
      code_security                         = optional(string)
      secret_scanning                       = optional(string)
      secret_scanning_push_protection       = optional(string)
      secret_scanning_ai_detection          = optional(string)
      secret_scanning_non_provider_patterns = optional(string)
    }), {})

    # Dependabot (repo-sec-001, repo-sec-007)
    dependabot_enabled = optional(bool, true)

    # Branch protection ruleset (repo-bp-001..013)
    ruleset_enabled = optional(bool, true)
    ruleset_bypass_actors = optional(list(object({
      actor_id    = optional(number)
      actor_type  = string
      bypass_mode = optional(string)
    })), [])
    ruleset_rules = optional(object({
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

    # GitHub Actions policy
    actions_policy_enabled = optional(bool, true)
    manage_allowed_actions = optional(bool)
    actions_patterns       = optional(list(string), [])

    # Access (repo-acc-001..005)
    team_permissions = optional(map(string), {})
    deploy_keys      = optional(map(string), {})

    # Committed security files (repo-sec-004..006, repo-sec-008, repo-sec-009)
    security_policy_file = optional(bool, true)
    security_contact     = optional(string)
    codeowners_file      = optional(bool, true)
    codeowners           = optional(list(string), [])
    dependabot_file      = optional(bool, true)
    dependabot_ecosystems = optional(list(object({
      package_ecosystem = string
      directory         = optional(string, "/")
      interval          = optional(string, "weekly")
    })), [])
    codeql_workflow  = optional(bool, true)
    codeql_languages = optional(list(string), ["actions"])
    overwrite_files  = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, repository in var.repositories : can(regex("^[A-Za-z0-9._-]+$", name))
    ])
    error_message = "repositories keys must be valid repository names."
  }

  validation {
    condition = alltrue([
      for repository in var.repositories : length(repository.codeql_languages) > 0
    ])
    error_message = "codeql_languages must not be empty."
  }
}
