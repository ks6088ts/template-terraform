module "organization_security_defaults" {
  source = "../../modules/github/organization_security_defaults"
  count  = var.enable_security_defaults ? 1 : 0

  billing_email = var.billing_email

  default_repository_permission                                = var.security_defaults.default_repository_permission
  members_can_create_repositories                              = var.security_defaults.members_can_create_repositories
  members_can_create_public_repositories                       = var.security_defaults.members_can_create_public_repositories
  members_can_create_private_repositories                      = var.security_defaults.members_can_create_private_repositories
  members_can_create_public_pages                              = var.security_defaults.members_can_create_public_pages
  members_can_fork_private_repositories                        = var.security_defaults.members_can_fork_private_repositories
  web_commit_signoff_required                                  = var.security_defaults.web_commit_signoff_required
  advanced_security_enabled_for_new_repositories               = var.security_defaults.advanced_security_enabled_for_new_repositories
  dependabot_alerts_enabled_for_new_repositories               = var.security_defaults.dependabot_alerts_enabled_for_new_repositories
  dependabot_security_updates_enabled_for_new_repositories     = var.security_defaults.dependabot_security_updates_enabled_for_new_repositories
  dependency_graph_enabled_for_new_repositories                = var.security_defaults.dependency_graph_enabled_for_new_repositories
  secret_scanning_enabled_for_new_repositories                 = var.security_defaults.secret_scanning_enabled_for_new_repositories
  secret_scanning_push_protection_enabled_for_new_repositories = var.security_defaults.secret_scanning_push_protection_enabled_for_new_repositories
}

module "organization_actions_policy" {
  source = "../../modules/github/organization_actions_policy"
  count  = var.enable_actions_policy ? 1 : 0

  organization_slug                = var.organization
  default_workflow_permissions     = var.actions_policy.default_workflow_permissions
  can_approve_pull_request_reviews = var.actions_policy.can_approve_pull_request_reviews
  allowed_actions                  = var.actions_policy.allowed_actions
  sha_pinning_required             = var.actions_policy.sha_pinning_required
  allowed_actions_config = {
    verified_allowed = var.actions_policy.verified_allowed
    patterns_allowed = var.actions_policy.patterns_allowed
  }
}

module "organization_security_manager" {
  source = "../../modules/github/organization_security_manager"
  count  = var.security_manager_team == null ? 0 : 1

  team_slug        = var.security_manager_team.slug
  create_team      = var.security_manager_team.create
  team_description = var.security_manager_team.description
}

module "organization_ruleset" {
  source = "../../modules/github/organization_ruleset"
  count  = var.enable_organization_ruleset ? 1 : 0

  name                    = var.organization_ruleset.name
  enforcement             = var.organization_ruleset.enforcement
  repository_name_include = var.organization_ruleset.repository_name_include
  repository_name_exclude = var.organization_ruleset.repository_name_exclude
  bypass_actors           = var.organization_ruleset.bypass_actors
  rules                   = var.organization_ruleset.rules
}
