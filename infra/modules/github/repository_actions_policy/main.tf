resource "github_workflow_repository_permissions" "this" {
  repository                       = var.repository
  default_workflow_permissions     = var.default_workflow_permissions
  can_approve_pull_request_reviews = var.can_approve_pull_request_reviews
}

resource "github_actions_repository_permissions" "this" {
  count = var.manage_allowed_actions ? 1 : 0

  repository           = var.repository
  enabled              = true
  allowed_actions      = var.allowed_actions
  sha_pinning_required = var.sha_pinning_required

  dynamic "allowed_actions_config" {
    for_each = var.allowed_actions == "selected" ? [var.allowed_actions_config] : []
    content {
      github_owned_allowed = allowed_actions_config.value.github_owned_allowed
      verified_allowed     = allowed_actions_config.value.verified_allowed
      patterns_allowed     = allowed_actions_config.value.patterns_allowed
    }
  }
}
