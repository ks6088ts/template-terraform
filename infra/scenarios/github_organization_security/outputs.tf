output "organization" {
  description = "Login of the managed organization, or null"
  value       = var.organization
}

output "security_defaults" {
  description = "Applied organization security settings, or null when security defaults are not managed"
  value       = one(module.organization_security_defaults[*].settings)
}

output "actions_default_workflow_permissions" {
  description = "Default GITHUB_TOKEN permission, or null when the Actions policy is not managed"
  value       = one(module.organization_actions_policy[*].default_workflow_permissions)
}

output "actions_allowed_actions" {
  description = "Allowed actions policy, or null when the Actions policy is not managed"
  value       = one(module.organization_actions_policy[*].allowed_actions)
}

output "security_manager_team_slug" {
  description = "Team assigned the security manager role, or null when not managed"
  value       = one(module.organization_security_manager[*].team_slug)
}

output "organization_ruleset_name" {
  description = "Name of the organization ruleset, or null when disabled"
  value       = one(module.organization_ruleset[*].name)
}
