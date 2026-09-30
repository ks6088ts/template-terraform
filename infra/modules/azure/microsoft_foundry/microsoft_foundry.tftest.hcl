mock_provider "azapi" {
  override_during = plan

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/foundry-test"
      output = {
        identity = {
          principalId = "00000000-0000-0000-0000-000000000001"
        }
        properties = {
          internalId = "11111111222233334444555555555555"
        }
      }
    }
  }
}

run "uses_current_stable_contracts" {
  command = plan

  variables {
    name               = "foundry-test"
    resource_group_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
    location           = "japaneast"
    disable_local_auth = true
    model_deployments = [
      {
        name                   = "chat"
        model                  = "gpt-5.4-mini"
        version                = "2026-03-17"
        capacity               = 100
        version_upgrade_option = "NoAutoUpgrade"
      },
    ]
  }

  assert {
    condition = alltrue([
      azapi_resource.account.type == "Microsoft.CognitiveServices/accounts@2026-07-01",
      azapi_resource.account.body.kind == "AIServices",
      azapi_resource.account.body.properties.allowProjectManagement,
      azapi_resource.account.body.properties.disableLocalAuth,
      azapi_resource.account.body.properties.publicNetworkAccess == "Enabled",
      !azapi_resource.account.body.properties.restrictOutboundNetworkAccess,
      azapi_resource.project.type == "Microsoft.CognitiveServices/accounts/projects@2026-07-01",
      azapi_resource.project.body.identity.type == "SystemAssigned",
    ])
    error_message = "Foundry account and project must use the current stable keyless-capable contracts."
  }

  assert {
    condition = alltrue([
      azapi_resource.deployment["chat"].type == "Microsoft.CognitiveServices/accounts/deployments@2026-07-01",
      azapi_resource.deployment["chat"].body.properties.model.name == "gpt-5.4-mini",
      azapi_resource.deployment["chat"].body.properties.versionUpgradeOption == "NoAutoUpgrade",
      azapi_resource.deployment["chat"].body.sku.capacity == 100,
      length(azapi_resource.deployment["chat"].replace_triggers_refs) == 1,
      contains(azapi_resource.deployment["chat"].replace_triggers_refs, "body.properties.model"),
    ])
    error_message = "Model deployments must use the stable contract and explicit replacement/version lifecycle."
  }

  assert {
    condition = alltrue([
      output.project_principal_id == "00000000-0000-0000-0000-000000000001",
      output.project_internal_id == "11111111222233334444555555555555",
      toset(keys(output.deployment_ids)) == toset(["chat"]),
    ])
    error_message = "Foundry module outputs must expose project identity and deployment metadata."
  }
}

run "rejects_duplicate_deployment_names" {
  command = plan

  variables {
    name              = "foundry-test"
    resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
    location          = "japaneast"
    model_deployments = [
      {
        name     = "duplicate"
        model    = "gpt-5.4-mini"
        version  = "2026-03-17"
        capacity = 100
      },
      {
        name     = "duplicate"
        model    = "text-embedding-3-large"
        version  = "1"
        capacity = 30
      },
    ]
  }

  expect_failures = [
    var.model_deployments,
  ]
}

run "rejects_invalid_deployment_lifecycle" {
  command = plan

  variables {
    name              = "foundry-test"
    resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
    location          = "japaneast"
    model_deployments = [
      {
        name                   = "chat"
        model                  = "gpt-5.4-mini"
        version                = "2026-03-17"
        capacity               = 0
        version_upgrade_option = "Unexpected"
      },
    ]
  }

  expect_failures = [
    var.model_deployments,
  ]
}
