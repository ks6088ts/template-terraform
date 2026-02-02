locals {
  account_name = "msfoundry${module.random_string.result}"
  project_name = "${local.account_name}project"
}
