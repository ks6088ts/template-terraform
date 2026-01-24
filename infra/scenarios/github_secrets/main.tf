resource "github_repository_environment" "this" {
  environment         = var.environment_name
  repository          = var.repository_name
  prevent_self_review = true
  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }
}

resource "github_actions_environment_secret" "this" {
  for_each = { for secret in var.actions_environment_secrets : secret.name => secret }

  repository      = var.repository_name
  environment     = github_repository_environment.this.environment
  secret_name     = each.value.name
  plaintext_value = each.value.value
}
