resource "github_team_repository" "this" {
  for_each = var.team_permissions

  team_id    = each.key
  repository = var.repository
  permission = each.value
}

resource "github_repository_deploy_key" "this" {
  for_each = var.deploy_keys

  repository = var.repository
  title      = each.key
  key        = each.value
  read_only  = true
}
