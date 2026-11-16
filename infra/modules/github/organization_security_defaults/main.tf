# github_organization_settings owns every organization setting, so unspecified
# arguments are reset to the provider defaults on apply.
resource "github_organization_settings" "this" {
  billing_email = var.billing_email
  name          = var.name
  description   = var.description

  default_repository_permission           = var.default_repository_permission
  members_can_create_repositories         = var.members_can_create_repositories
  members_can_create_public_repositories  = var.members_can_create_public_repositories
  members_can_create_private_repositories = var.members_can_create_private_repositories
  members_can_create_public_pages         = var.members_can_create_public_pages
  members_can_fork_private_repositories   = var.members_can_fork_private_repositories
  web_commit_signoff_required             = var.web_commit_signoff_required

  advanced_security_enabled_for_new_repositories               = var.advanced_security_enabled_for_new_repositories
  dependabot_alerts_enabled_for_new_repositories               = var.dependabot_alerts_enabled_for_new_repositories
  dependabot_security_updates_enabled_for_new_repositories     = var.dependabot_security_updates_enabled_for_new_repositories
  dependency_graph_enabled_for_new_repositories                = var.dependency_graph_enabled_for_new_repositories
  secret_scanning_enabled_for_new_repositories                 = var.secret_scanning_enabled_for_new_repositories
  secret_scanning_push_protection_enabled_for_new_repositories = var.secret_scanning_push_protection_enabled_for_new_repositories
}
