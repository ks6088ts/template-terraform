data "github_organization_roles" "this" {}

locals {
  security_manager_role_id = one([
    for role in data.github_organization_roles.this.roles : role.role_id
    if role.name == "security_manager"
  ])
  team_slug = var.create_team ? github_team.this[0].slug : var.team_slug
}

resource "github_team" "this" {
  count = var.create_team ? 1 : 0

  name        = var.team_slug
  description = var.team_description
  privacy     = "closed"
}

resource "github_organization_role_team" "this" {
  role_id   = local.security_manager_role_id
  team_slug = local.team_slug

  lifecycle {
    precondition {
      condition     = local.security_manager_role_id != null
      error_message = "The organization has no security_manager role."
    }
  }
}
