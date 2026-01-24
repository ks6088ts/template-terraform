locals {
  account_name = "msfoundry${random_string.unique.result}"
  project_name = "${local.account_name}project"
}
