output "default_workflow_permissions" {
  description = "Configured default GITHUB_TOKEN permission"
  value       = github_workflow_repository_permissions.this.default_workflow_permissions
}

output "allowed_actions" {
  description = "Configured allowed actions policy, or null when not managed"
  value       = one(github_actions_repository_permissions.this[*].allowed_actions)
}
