resource "github_repository_file" "this" {
  for_each = var.files

  repository          = var.repository
  branch              = var.branch
  file                = each.key
  content             = each.value
  commit_message      = "${var.commit_message_prefix} ${each.key}"
  overwrite_on_create = var.overwrite_on_create
}
