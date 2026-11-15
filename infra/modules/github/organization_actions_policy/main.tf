resource "github_actions_organization_workflow_permissions" "this" {
  organization_slug                = var.organization_slug
  default_workflow_permissions     = var.default_workflow_permissions
  can_approve_pull_request_reviews = var.can_approve_pull_request_reviews
}

resource "github_actions_organization_permissions" "this" {
  enabled_repositories = var.enabled_repositories
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

  dynamic "enabled_repositories_config" {
    for_each = var.enabled_repositories == "selected" ? [var.enabled_repository_ids] : []
    content {
      repository_ids = enabled_repositories_config.value
    }
  }
}
