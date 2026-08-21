resource "random_string" "this" {
  keepers     = var.keepers
  length      = var.length
  min_numeric = var.min_numeric
  numeric     = var.numeric
  special     = var.special
  lower       = var.lower
  upper       = var.upper
}
