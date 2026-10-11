data "cloudflare_account" "this" {
  account_id = var.account_id

  lifecycle {
    postcondition {
      condition     = self.id == var.account_id
      error_message = "The returned Cloudflare Account ID must match the requested account_id."
    }
  }
}
