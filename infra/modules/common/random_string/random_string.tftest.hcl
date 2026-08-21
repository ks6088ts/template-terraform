mock_provider "random" {
  override_during = plan

  mock_resource "random_string" {
    defaults = {
      result = "test1234"
    }
  }
}

run "keepers_are_empty_by_default" {
  command = plan

  assert {
    condition     = length(random_string.this.keepers) == 0
    error_message = "The random string must not have replacement keepers unless callers opt in."
  }
}

run "keepers_are_forwarded" {
  command = plan

  variables {
    keepers = {
      apim_sku_family = "dedicated"
      location        = "eastus2"
    }
  }

  assert {
    condition = random_string.this.keepers == tomap({
      apim_sku_family = "dedicated"
      location        = "eastus2"
    })
    error_message = "Configured keepers must be forwarded to the random string resource."
  }
}
