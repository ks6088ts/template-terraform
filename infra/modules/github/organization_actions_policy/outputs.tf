output "default_workflow_permissions" {
  description = "Configured default GITHUB_TOKEN permission"
  value       = github_actions_organization_workflow_permissions.this.default_workflow_permissions
}

output "allowed_actions" {
  description = "Configured allowed actions policy"
  value       = github_actions_organization_permissions.this.allowed_actions
}
