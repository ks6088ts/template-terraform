sku_name = "Developer_1"

backend_pool = {
  primary_weight   = 3
  secondary_weight = 1
  circuit_breaker = {
    failure_count = 2
  }
}

ai_backend = {
  provision = {
    deployment_name = "gpt-4o-mini"
    model           = "gpt-4o-mini"
    version         = "2024-07-18"
    sku_name        = "GlobalStandard"
    capacity        = 10
  }
}

llm_token_limit = {
  tokens_per_minute      = 100
  token_quota            = 10000
  token_quota_period     = "Monthly"
  estimate_prompt_tokens = true
}

content_safety = {
  provision = {
    sku_name = "S0"
  }
  blocklist_name         = "apim-playground"
  shield_prompt          = true
  enforce_on_completions = true
}

observability = {
  retention_in_days   = 30
  sampling_percentage = 100
  verbosity           = "information"
  log_client_ip       = false
  llm_logging = {
    log_prompts     = false
    log_completions = false
  }
}

llm_token_metrics = {
  namespace = "APIM Playground"
  dimensions = [
    "API ID",
    "Subscription ID",
    "Backend ID",
  ]
}
