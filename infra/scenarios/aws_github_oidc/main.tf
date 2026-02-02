module "github_oidc" {
  source = "../../modules/aws/github_oidc"

  github_organization  = var.github_organization
  github_repository    = var.github_repository
  role_name            = var.role_name
  policy_arns          = var.policy_arns
  github_branches      = var.github_branches
  github_environments  = var.github_environments
  tags                 = var.tags
}
