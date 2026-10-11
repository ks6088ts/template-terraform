module "account" {
  source = "../../modules/cloudflare/account"

  account_id = var.account_id
}
