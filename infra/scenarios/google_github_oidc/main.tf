module "github_oidc" {
  source = "../../modules/google/github_oidc"

  project_id                                   = var.project_id
  github_organization                          = var.github_organization
  github_repository                            = var.github_repository
  workload_identity_pool_id                    = var.workload_identity_pool_id
  workload_identity_pool_display_name          = var.workload_identity_pool_display_name
  workload_identity_pool_provider_id           = var.workload_identity_pool_provider_id
  workload_identity_pool_provider_display_name = var.workload_identity_pool_provider_display_name
  service_account_id                           = var.service_account_id
  service_account_display_name                 = var.service_account_display_name
  roles                                        = var.roles
}
