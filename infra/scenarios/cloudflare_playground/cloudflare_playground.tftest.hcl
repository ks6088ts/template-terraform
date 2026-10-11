mock_provider "cloudflare" {
  override_during = plan

  mock_data "cloudflare_account" {
    defaults = {
      id   = "023e105f4ecef8ad9ca31a8372d0c353"
      name = "Example Account"
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "expose_existing_account" {
  command = plan

  assert {
    condition = alltrue([
      output.account_id == "023e105f4ecef8ad9ca31a8372d0c353",
      output.account_name == "Example Account",
      output.account_id == module.account.id,
      output.account_name == module.account.name,
    ])
    error_message = "The scenario must expose the account module's ID and name."
  }
}

run "expose_another_account" {
  command = plan

  variables {
    account_id = "123e105f4ecef8ad9ca31a8372d0c353"
  }

  override_data {
    target = module.account.data.cloudflare_account.this
    values = {
      id   = "123e105f4ecef8ad9ca31a8372d0c353"
      name = "Another Account"
    }
  }

  assert {
    condition = alltrue([
      output.account_id == "123e105f4ecef8ad9ca31a8372d0c353",
      output.account_name == "Another Account",
      output.account_id == module.account.id,
      output.account_name == module.account.name,
    ])
    error_message = "The scenario must expose the selected account rather than fixed output values."
  }
}

run "reject_empty_account_id" {
  command = plan

  variables {
    account_id = ""
  }

  expect_failures = [var.account_id]
}

run "reject_short_account_id" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c35"
  }

  expect_failures = [var.account_id]
}

run "reject_long_account_id" {
  command = plan

  variables {
    account_id = "023e105f4ecef8ad9ca31a8372d0c3530"
  }

  expect_failures = [var.account_id]
}

run "reject_non_hexadecimal_account_id" {
  command = plan

  variables {
    account_id = "z23e105f4ecef8ad9ca31a8372d0c353"
  }

  expect_failures = [var.account_id]
}

run "reject_uppercase_account_id" {
  command = plan

  variables {
    account_id = "023E105F4ECEF8AD9CA31A8372D0C353"
  }

  expect_failures = [var.account_id]
}

run "reject_account_id_with_whitespace" {
  command = plan

  variables {
    account_id = " 023e105f4ecef8ad9ca31a8372d0c353 "
  }

  expect_failures = [var.account_id]
}
