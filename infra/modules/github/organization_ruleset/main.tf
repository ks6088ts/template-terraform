resource "github_organization_ruleset" "this" {
  name        = var.name
  target      = "branch"
  enforcement = var.enforcement

  conditions {
    ref_name {
      include = var.ref_name_include
      exclude = var.ref_name_exclude
    }

    repository_name {
      include = var.repository_name_include
      exclude = var.repository_name_exclude
    }
  }

  dynamic "bypass_actors" {
    for_each = var.bypass_actors
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }

  rules {
    non_fast_forward        = var.rules.non_fast_forward
    deletion                = var.rules.deletion
    required_signatures     = var.rules.required_signatures
    required_linear_history = var.rules.required_linear_history

    pull_request {
      required_approving_review_count   = var.rules.required_approving_review_count
      dismiss_stale_reviews_on_push     = var.rules.dismiss_stale_reviews_on_push
      require_code_owner_review         = var.rules.require_code_owner_review
      require_last_push_approval        = var.rules.require_last_push_approval
      required_review_thread_resolution = var.rules.required_review_thread_resolution
      allowed_merge_methods             = var.rules.allowed_merge_methods
    }

    dynamic "required_status_checks" {
      for_each = length(var.rules.required_status_checks) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = var.rules.strict_required_status_checks_policy

        dynamic "required_check" {
          for_each = var.rules.required_status_checks
          content {
            context        = required_check.value.context
            integration_id = required_check.value.integration_id
          }
        }
      }
    }

    dynamic "required_code_scanning" {
      for_each = length(var.rules.required_code_scanning) > 0 ? [1] : []
      content {
        dynamic "required_code_scanning_tool" {
          for_each = var.rules.required_code_scanning
          content {
            tool                      = required_code_scanning_tool.value.tool
            alerts_threshold          = required_code_scanning_tool.value.alerts_threshold
            security_alerts_threshold = required_code_scanning_tool.value.security_alerts_threshold
          }
        }
      }
    }
  }
}
