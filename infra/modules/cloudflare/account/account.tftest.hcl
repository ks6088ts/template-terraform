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

run "read_existing_account" {
  command = plan

  assert {
    condition     = data.cloudflare_account.this.account_id == var.account_id
    error_message = "The datasource must read the configured Account ID."
  }

  assert {
    condition = alltrue([
      output.id == "023e105f4ecef8ad9ca31a8372d0c353",
      output.name == "Example Account",
    ])
    error_message = "The module must expose the account ID and name returned by the datasource."
  }
}

run "read_another_account" {
  command = plan

  variables {
    account_id = "123e105f4ecef8ad9ca31a8372d0c353"
  }

  override_data {
    target = data.cloudflare_account.this
    values = {
      id   = "123e105f4ecef8ad9ca31a8372d0c353"
      name = "Another Account"
    }
  }

  assert {
    condition = alltrue([
      data.cloudflare_account.this.account_id == var.account_id,
      output.id == "123e105f4ecef8ad9ca31a8372d0c353",
      output.name == "Another Account",
    ])
    error_message = "The module must forward a different Account ID and expose its returned attributes."
  }
}

run "reject_empty_account_id" {
  command = plan

  variables {
    account_id = ""
  }

  expect_failures = [var.account_id]
}

run "reject_mismatched_account_id" {
  command = plan

  override_data {
    target = data.cloudflare_account.this
    values = {
      id   = "123e105f4ecef8ad9ca31a8372d0c353"
      name = "Another Account"
    }
  }

  expect_failures = [data.cloudflare_account.this]
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
