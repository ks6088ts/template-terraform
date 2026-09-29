mock_provider "azurerm" {
  override_during = plan

  mock_data "azurerm_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000005"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
    }
  }

  mock_resource "azurerm_api_management" {
    defaults = {
      id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ApiManagement/service/apim-test1234"
      gateway_url = "https://mock-api-management-gateway-url"
      identity = {
        principal_id = "00000000-0000-0000-0000-000000000001"
        tenant_id    = "00000000-0000-0000-0000-000000000002"
      }
    }
  }

  mock_resource "azurerm_container_app" {
    defaults = {
      latest_revision_fqdn = "mock-backend.example.com"
    }
  }

  mock_resource "azurerm_api_management_backend" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ApiManagement/service/apim-test1234/backends/mock-backend"
    }
  }

  mock_resource "azurerm_cognitive_account" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/contentsafetytest1234"
      endpoint = "https://contentsafetytest1234.cognitiveservices.azure.com/"
    }
  }

  mock_resource "azurerm_application_insights" {
    defaults = {
      id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/components/appi-test1234"
      app_id            = "00000000-0000-0000-0000-000000000006"
      connection_string = "InstrumentationKey=00000000-0000-0000-0000-000000000007"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/stapimtest1234"
    }
  }
}

mock_provider "random" {
  override_during = plan

  mock_resource "random_string" {
    defaults = {
      result = "test1234"
    }
  }

  mock_resource "random_password" {
    defaults = {
      result = "0123456789abcdef0123456789abcdef"
    }
  }
}

mock_provider "azapi" {
  override_during = plan

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/aifoundrytest1234"
      output = {
        identity = {
          principalId = "00000000-0000-0000-0000-000000000003"
        }
      }
    }
  }
}

run "core_api_is_deployed_by_default" {
  command = plan

  assert {
    condition = alltrue([
      var.location == "eastus2",
      module.resource_group.location == "eastus2",
    ])
    error_message = "The default deployment must use East US 2."
  }

  assert {
    condition = alltrue([
      azurerm_api_management_api_version_set.core.versioning_scheme == "Segment",
      azurerm_api_management_api.core.version == "v1",
      azurerm_api_management_api.core.subscription_required,
      azurerm_api_management_product.playground.published,
      azurerm_api_management_product.playground.subscription_required,
      azurerm_api_management_subscription.playground.state == "active",
    ])
    error_message = "The versioned core API, published product, and active subscription must be deployed by default."
  }

  assert {
    condition = alltrue([
      azurerm_api_management_api_operation_policy.hello.operation_id == "get-hello",
      strcontains(azurerm_api_management_api_operation_policy.hello.xml_content, "return-response"),
      azurerm_api_management_api_operation_policy.mock.operation_id == "get-mock",
      strcontains(azurerm_api_management_api_operation_policy.mock.xml_content, "mock-response"),
    ])
    error_message = "The core operations must use deterministic return-response and mock-response policies."
  }

  assert {
    condition = alltrue([
      strcontains(azurerm_api_management_api_policy.core.xml_content, "rate-limit"),
      strcontains(azurerm_api_management_api_policy.core.xml_content, "Ocp-Apim-Subscription-Key"),
      strcontains(azurerm_api_management_api_policy.core.xml_content, "subscription-key"),
      strcontains(azurerm_api_management_api_policy.core.xml_content, local.core_policy_fragment_name),
    ])
    error_message = "The core API policy must apply rate limiting, remove subscription credentials, and include the response fragment."
  }

  assert {
    condition = alltrue([
      output.playground_subscription_primary_key == random_password.subscription_primary_key.result,
      output.playground_subscription_secondary_key == random_password.subscription_secondary_key.result,
      output.core_api_url == "https://mock-api-management-gateway-url/playground/v1",
    ])
    error_message = "The subscription keys and versioned core URL must be wired to their managed resources."
  }

  assert {
    condition = alltrue([
      length(azurerm_container_app_environment.backends) == 0,
      length(azurerm_container_app.backend) == 0,
      length(azurerm_api_management_backend.resilience) == 0,
      length(azapi_resource.weighted_pool) == 0,
      length(azurerm_api_management_api.resilience) == 0,
      !output.backend_pool_enabled,
      !output.circuit_breaker_enabled,
      length(module.ai_foundry) == 0,
      length(azurerm_api_management_backend.ai) == 0,
      length(azurerm_api_management_api.ai) == 0,
      length(azurerm_role_assignment.apim_ai_user) == 0,
      !output.ai_backend_enabled,
      !output.llm_token_limit_enabled,
      length(azurerm_cognitive_account.content_safety) == 0,
      length(azapi_resource.content_safety_backend) == 0,
      length(azurerm_role_assignment.apim_content_safety_user) == 0,
      length(azurerm_role_assignment.operator_content_safety_user) == 0,
      !output.content_safety_enabled,
      length(module.log_analytics) == 0,
      length(module.application_insights) == 0,
      length(azapi_update_resource.application_insights_custom_metrics) == 0,
      length(azurerm_api_management_logger.application_insights) == 0,
      length(azapi_resource.application_insights_diagnostic) == 0,
      length(azurerm_monitor_diagnostic_setting.api_management) == 0,
      length(azapi_resource.ai_llm_diagnostic) == 0,
      !output.observability_enabled,
      !output.llm_logging_enabled,
      !output.llm_token_metrics_enabled,
      length(azurerm_api_management_policy_fragment.caller_attribution) == 0,
      length(azurerm_api_management_policy_fragment.stream_usage) == 0,
      length(azurerm_api_management_subscription.business_unit) == 0,
      length(azapi_resource.cost_workbook) == 0,
      length(azurerm_storage_account.cost_export) == 0,
      length(azapi_resource.cost_export) == 0,
      length(azurerm_monitor_action_group.request_threshold) == 0,
      length(azurerm_monitor_scheduled_query_rules_alert_v2.request_threshold) == 0,
      !output.cost_showback_enabled,
    ])
    error_message = "Optional backend pool and AI resources must remain disabled by default."
  }
}


run "weighted_backend_pool_enabled" {
  command = plan

  variables {
    backend_pool = {
      primary_weight               = 3
      secondary_weight             = 1
      session_affinity_cookie_name = "PlaygroundSession"
    }
  }

  assert {
    condition = alltrue([
      length(azurerm_container_app_environment.backends) == 1,
      length(azurerm_container_app.backend) == 2,
      length(azurerm_api_management_backend.resilience) == 2,
      length(azapi_resource.weighted_pool) == 1,
      length(azurerm_api_management_api.resilience) == 1,
      length(azurerm_api_management_backend.failing_primary) == 0,
      length(azapi_resource.failover_pool) == 0,
      output.backend_pool_enabled,
      !output.circuit_breaker_enabled,
    ])
    error_message = "The weighted backend pool must deploy two apps and two member backends without failover resources."
  }

  assert {
    condition = alltrue([
      azapi_resource.weighted_pool[0].body.properties.type == "Pool",
      azapi_resource.weighted_pool[0].body.properties.pool.services[0].weight == 3,
      azapi_resource.weighted_pool[0].body.properties.pool.services[1].weight == 1,
      azapi_resource.weighted_pool[0].body.properties.pool.sessionAffinity.sessionId.source == "cookie",
      azapi_resource.weighted_pool[0].body.properties.pool.sessionAffinity.sessionId.name == "PlaygroundSession",
    ])
    error_message = "The weighted pool must preserve configured weights and session affinity."
  }

  assert {
    condition     = strcontains(azurerm_api_management_api_operation_policy.failover[0].xml_content, "501")
    error_message = "The failover operation must return 501 when the circuit breaker is disabled."
  }
}


run "circuit_breaker_enabled" {
  command = plan

  variables {
    sku_name = "Developer_1"
    backend_pool = {
      circuit_breaker = {
        failure_count      = 2
        interval_duration  = "PT1M"
        trip_duration      = "PT2M"
        accept_retry_after = true
      }
    }
  }

  assert {
    condition = alltrue([
      length(azurerm_api_management_backend.failing_primary) == 1,
      length(azapi_resource.failover_pool) == 1,
      azurerm_api_management_backend.failing_primary[0].circuit_breaker_rule[0].failure_condition[0].count == 2,
      azurerm_api_management_backend.failing_primary[0].circuit_breaker_rule[0].trip_duration == "PT2M",
      azapi_resource.failover_pool[0].body.properties.pool.services[0].priority == 1,
      azapi_resource.failover_pool[0].body.properties.pool.services[1].priority == 2,
      strcontains(azurerm_api_management_api_operation_policy.failover[0].xml_content, local.failover_pool_name),
      output.circuit_breaker_enabled,
    ])
    error_message = "Developer tier circuit-breaker configuration must create the failing backend and priority pool."
  }
}


run "consumption_rejects_circuit_breaker" {
  command = plan

  variables {
    sku_name = "Consumption_0"
    backend_pool = {
      circuit_breaker = {}
    }
  }

  expect_failures = [terraform_data.feature_validation]
}


run "existing_ai_backend_enabled" {
  command = plan

  variables {
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
  }

  assert {
    condition = alltrue([
      length(module.ai_foundry) == 0,
      length(azurerm_api_management_backend.ai) == 1,
      length(azurerm_api_management_api.ai) == 1,
      length(azurerm_role_assignment.apim_ai_user) == 1,
      azurerm_role_assignment.apim_ai_user[0].role_definition_name == "Cognitive Services User",
      azurerm_api_management_backend.ai[0].url == "https://existing.openai.azure.com/openai/v1",
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "authentication-managed-identity"),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "playground-ensure-stream-include-usage"),
      length(azurerm_api_management_policy_fragment.stream_usage) == 1,
      strcontains(azurerm_api_management_api.ai[0].import[0].content_value, "\"/responses\""),
      strcontains(azurerm_api_management_api.ai[0].import[0].content_value, "\"create-response\""),
      !strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "llm-token-limit"),
      output.ai_backend_mode == "existing",
      output.ai_deployment_name == "gpt-test",
      output.ai_reasoning_effort == null,
    ])
    error_message = "Existing AI mode must create a managed-identity gateway without provisioning a Foundry account."
  }
}


run "provisioned_ai_backend_enabled" {
  command = plan

  variables {
    ai_backend = {
      reasoning_effort = "none"
      provision = {
        deployment_name = "gpt-5.4-mini"
        model           = "gpt-5.4-mini"
        version         = "2026-03-17"
        capacity        = 10
      }
    }
  }

  assert {
    condition = alltrue([
      length(module.ai_foundry) == 1,
      module.ai_foundry[0].openai_endpoint == "https://aifoundrytest1234.openai.azure.com/",
      module.ai_foundry[0].deployment_ids["gpt-5.4-mini"] != null,
      azurerm_api_management_backend.ai[0].url == "https://aifoundrytest1234.openai.azure.com/openai/v1",
      local.ai_provision_config.model == "gpt-5.4-mini",
      local.ai_provision_config.version == "2026-03-17",
      local.ai_provision_config.sku_name == "DataZoneStandard",
      output.ai_reasoning_effort == "none",
      output.ai_backend_mode == "provision",
      output.ai_deployment_name == "gpt-5.4-mini",
    ])
    error_message = "Provisioned AI mode must create one Foundry account and route APIM to its OpenAI v1 endpoint."
  }
}


run "ai_backend_rejects_invalid_reasoning_effort" {
  command = plan

  variables {
    ai_backend = {
      reasoning_effort = "unsupported"
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
  }

  expect_failures = [var.ai_backend]
}


run "llm_token_limit_enabled" {
  command = plan

  variables {
    sku_name = "Developer_1"
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
    llm_token_limit = {
      tokens_per_minute  = 1000
      token_quota        = 10000
      token_quota_period = "Monthly"
    }
  }

  assert {
    condition = alltrue([
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "llm-token-limit"),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "tokens-per-minute=\"1000\""),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "token-quota=\"10000\""),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "token-quota-period=\"Monthly\""),
      output.llm_token_limit_enabled,
    ])
    error_message = "The configured LLM token rate limit and quota must be rendered into the AI API policy."
  }
}


run "token_limit_requires_ai_backend" {
  command = plan

  variables {
    sku_name = "Developer_1"
    llm_token_limit = {
      tokens_per_minute = 1000
    }
  }

  expect_failures = [terraform_data.feature_validation]
}


run "consumption_rejects_token_limit" {
  command = plan

  variables {
    sku_name = "Consumption_0"
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
    llm_token_limit = {
      tokens_per_minute = 1000
    }
  }

  expect_failures = [terraform_data.feature_validation]
}


run "provisioned_content_safety_enabled" {
  command = plan

  variables {
    sku_name              = "Developer_1"
    operator_principal_id = "00000000-0000-0000-0000-000000000004"
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
    content_safety = {
      provision = {
        sku_name = "S0"
      }
      blocklist_name         = "playground-terms"
      shield_prompt          = true
      enforce_on_completions = true
      categories = {
        Hate     = 3
        Violence = 4
      }
    }
  }

  assert {
    condition = alltrue([
      length(azurerm_cognitive_account.content_safety) == 1,
      azurerm_cognitive_account.content_safety[0].kind == "ContentSafety",
      !azurerm_cognitive_account.content_safety[0].local_auth_enabled,
      length(azapi_resource.content_safety_backend) == 1,
      azapi_resource.content_safety_backend[0].body.properties.credentials.managedIdentity.resource == "https://cognitiveservices.azure.com",
      length(azurerm_role_assignment.apim_content_safety_user) == 1,
      length(azurerm_role_assignment.operator_content_safety_user) == 1,
      azurerm_role_assignment.operator_content_safety_user[0].principal_id == "00000000-0000-0000-0000-000000000004",
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "llm-content-safety"),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "playground-terms"),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "category name=\"Hate\" threshold=\"3\""),
      output.content_safety_mode == "provision",
    ])
    error_message = "Provisioned Content Safety must create a keyless resource, managed-identity backend, RBAC, and policy."
  }
}


run "existing_content_safety_enabled" {
  command = plan

  variables {
    sku_name = "Developer_1"
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
    content_safety = {
      existing = {
        endpoint    = "https://existing-safety.cognitiveservices.azure.com"
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-safety"
      }
    }
  }

  assert {
    condition = alltrue([
      length(azurerm_cognitive_account.content_safety) == 0,
      azapi_resource.content_safety_backend[0].body.properties.url == "https://existing-safety.cognitiveservices.azure.com",
      output.content_safety_mode == "existing",
      output.content_safety_resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-safety",
    ])
    error_message = "Existing Content Safety mode must reuse the supplied endpoint and resource ID."
  }
}


run "content_safety_requires_ai_backend" {
  command = plan

  variables {
    sku_name = "Developer_1"
    content_safety = {
      provision = {}
    }
  }

  expect_failures = [terraform_data.feature_validation]
}


run "consumption_rejects_content_safety" {
  command = plan

  variables {
    sku_name = "Consumption_0"
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
    content_safety = {
      provision = {}
    }
  }

  expect_failures = [terraform_data.feature_validation]
}


run "content_safety_rejects_multiple_ownership_modes" {
  command = plan

  variables {
    sku_name = "Developer_1"
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
    content_safety = {
      provision = {}
      existing = {
        endpoint    = "https://existing-safety.cognitiveservices.azure.com"
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-safety"
      }
    }
  }

  expect_failures = [var.content_safety]
}


run "observability_enabled" {
  command = plan

  variables {
    observability = {
      retention_in_days   = 60
      sampling_percentage = 50
      verbosity           = "information"
      log_client_ip       = false
    }
  }

  assert {
    condition = alltrue([
      length(module.log_analytics) == 1,
      length(module.application_insights) == 1,
      azurerm_role_assignment.apim_monitoring_metrics_publisher[0].role_definition_name == "Monitoring Metrics Publisher",
      azurerm_api_management_logger.application_insights[0].application_insights[0].identity_client_id == "SystemAssigned",
      azapi_resource.application_insights_diagnostic[0].body.properties.frontend.request.body.bytes == 0,
      azapi_resource.application_insights_diagnostic[0].body.properties.backend.response.body.bytes == 0,
      !azapi_resource.application_insights_diagnostic[0].body.properties.metrics,
      one(azurerm_monitor_diagnostic_setting.api_management[0].enabled_log).category_group == "allLogs",
      one(azurerm_monitor_diagnostic_setting.api_management[0].enabled_metric).category == "AllMetrics",
      output.observability_enabled,
    ])
    error_message = "Observability must deploy keyless Application Insights logging and all APIM logs to Log Analytics without body capture."
  }
}


run "llm_logging_enabled" {
  command = plan

  variables {
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
    observability = {
      llm_logging = {
        log_prompts               = true
        log_completions           = true
        max_message_size_in_bytes = 16384
      }
    }
  }

  assert {
    condition = alltrue([
      length(azapi_resource.ai_llm_diagnostic) == 1,
      azapi_resource.ai_llm_diagnostic[0].name == "azuremonitor",
      endswith(azapi_resource.ai_llm_diagnostic[0].body.properties.loggerId, "/loggers/azuremonitor"),
      !contains(keys(azapi_resource.ai_llm_diagnostic[0].body.properties), "httpCorrelationProtocol"),
      azapi_resource.ai_llm_diagnostic[0].body.properties.largeLanguageModel.logs == "enabled",
      azapi_resource.ai_llm_diagnostic[0].body.properties.largeLanguageModel.requests.messages == "all",
      azapi_resource.ai_llm_diagnostic[0].body.properties.largeLanguageModel.requests.maxSizeInBytes == 16384,
      azapi_resource.ai_llm_diagnostic[0].body.properties.largeLanguageModel.responses.messages == "all",
      output.llm_logging_enabled,
    ])
    error_message = "LLM logging must enable Azure Monitor usage, prompt, and completion diagnostics for the AI API."
  }
}


run "llm_token_metrics_enabled" {
  command = plan

  variables {
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
    observability = {}
    llm_token_metrics = {
      namespace = "APIM Playground Test"
      dimensions = [
        "API ID",
        "Subscription ID",
        "Backend ID",
      ]
    }
  }

  assert {
    condition = alltrue([
      azapi_resource.application_insights_diagnostic[0].body.properties.metrics,
      azapi_update_resource.application_insights_custom_metrics[0].body.properties.CustomMetricsOptedInType == "WithDimensions",
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "llm-emit-token-metric"),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "namespace=\"APIM Playground Test\""),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "dimension name=\"Backend ID\""),
      output.llm_token_metrics_enabled,
    ])
    error_message = "Token metrics must enable the Application Insights diagnostic metric flag and render the LLM token metric policy."
  }
}


run "llm_logging_requires_ai_backend" {
  command = plan

  variables {
    observability = {
      llm_logging = {}
    }
  }

  expect_failures = [terraform_data.feature_validation]
}


run "llm_token_metrics_requires_observability" {
  command = plan

  variables {
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
    llm_token_metrics = {}
  }

  expect_failures = [terraform_data.feature_validation]
}


run "llm_token_metrics_requires_ai_backend" {
  command = plan

  variables {
    observability     = {}
    llm_token_metrics = {}
  }

  expect_failures = [terraform_data.feature_validation]
}


run "cost_showback_enabled" {
  command = plan

  variables {
    ai_backend = {
      existing = {
        endpoint        = "https://existing.openai.azure.com/openai/v1"
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ai/providers/Microsoft.CognitiveServices/accounts/existing-ai"
        deployment_name = "gpt-test"
      }
    }
    observability = {
      llm_logging = {}
    }
    cost_showback = {
      business_units = {
        "bu-engineering" = "Engineering"
        "bu-finance"     = "Finance"
      }
      entra_id = {
        tenant_id = "00000000-0000-0000-0000-000000000008"
        audiences = ["api://apim-playground"]
      }
      base_monthly_cost               = 200
      per_1000_requests_cost          = 0.004
      prompt_per_1000_tokens_cost     = 0.001
      completion_per_1000_tokens_cost = 0.002
    }
  }

  assert {
    condition = alltrue([
      length(azurerm_api_management_policy_fragment.caller_attribution) == 1,
      length(azurerm_api_management_policy_fragment.stream_usage) == 1,
      length(azurerm_api_management_subscription.business_unit) == 2,
      length(azapi_resource.cost_workbook) == 1,
      azapi_update_resource.application_insights_custom_metrics[0].body.properties.CustomMetricsOptedInType == "WithDimensions",
      azapi_resource.application_insights_diagnostic[0].body.properties.metrics,
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "playground-caller-attribution"),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "validate-azure-ad-token"),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "api://apim-playground"),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "playground-ensure-stream-include-usage"),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "caller-requests"),
      strcontains(azurerm_api_management_api_policy.ai[0].xml_content, "x-business-unit"),
      strcontains(azapi_resource.cost_workbook[0].body.properties.serializedData, "200"),
      !strcontains(azapi_resource.cost_workbook[0].body.properties.serializedData, "__APP_INSIGHTS_NAME__"),
      !strcontains(azapi_resource.cost_workbook[0].body.properties.serializedData, "__BASE_MONTHLY_COST__"),
      !strcontains(azapi_resource.cost_workbook[0].body.properties.serializedData, "987654321.123456"),
      output.cost_showback_enabled,
    ])
    error_message = "Cost showback must create caller attribution, streaming usage, business-unit subscriptions, metrics, and the workbook."
  }
}


run "cost_export_and_request_alerts_enabled" {
  command = plan

  variables {
    observability = {}
    cost_showback = {
      business_units = {
        "bu-engineering" = "Engineering"
      }
      workbook_enabled = false
      cost_export = {
        start_date = "2026-09-01T00:00:00Z"
      }
      request_alerts = {
        email_address     = "apim-alerts@example.com"
        request_threshold = 500
      }
    }
  }

  assert {
    condition = alltrue([
      length(azapi_resource.cost_workbook) == 0,
      length(azurerm_storage_account.cost_export) == 1,
      length(azapi_resource.cost_export_container) == 1,
      length(azapi_resource.cost_export) == 1,
      azapi_resource.cost_export[0].body.properties.schedule.recurrence == "Daily",
      azapi_resource.cost_export[0].body.properties.schedule.recurrencePeriod.from == "2026-09-01T00:00:00Z",
      length(azurerm_monitor_action_group.request_threshold) == 1,
      length(azurerm_monitor_scheduled_query_rules_alert_v2.request_threshold) == 1,
      strcontains(azurerm_monitor_scheduled_query_rules_alert_v2.request_threshold["bu-engineering"].criteria[0].query, "RequestCount > 500"),
    ])
    error_message = "Cost export and request-threshold alerts must remain independent opt-ins under cost showback."
  }
}


run "cost_showback_requires_observability" {
  command = plan

  variables {
    cost_showback = {}
  }

  expect_failures = [terraform_data.feature_validation]
}


run "request_alerts_require_business_units" {
  command = plan

  variables {
    observability = {}
    cost_showback = {
      request_alerts = {
        email_address = "apim-alerts@example.com"
      }
    }
  }

  expect_failures = [terraform_data.feature_validation]
}
