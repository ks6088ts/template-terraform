module "repository_environment" {
  source = "../../modules/github/repository_environment"

  repository_name             = var.repository_name
  environment_name            = var.environment_name
  actions_environment_secrets = var.actions_environment_secrets
}
