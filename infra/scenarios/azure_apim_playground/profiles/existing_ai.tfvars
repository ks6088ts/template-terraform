sku_name = "Developer_1"

# Replace these values with an Azure AI account that exposes an OpenAI v1 endpoint.
ai_backend = {
  existing = {
    endpoint        = "https://replace-me.openai.azure.com/openai/v1"
    resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/replace-me/providers/Microsoft.CognitiveServices/accounts/replace-me"
    deployment_name = "replace-me"
  }
}

# Replace these values with an existing Azure AI Content Safety account.
content_safety = {
  existing = {
    endpoint    = "https://replace-me.cognitiveservices.azure.com"
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/replace-me/providers/Microsoft.CognitiveServices/accounts/replace-me-content-safety"
  }
  blocklist_name         = "apim-playground"
  shield_prompt          = true
  enforce_on_completions = true
}

llm_token_limit = {
  tokens_per_minute      = 100
  token_quota            = 10000
  token_quota_period     = "Monthly"
  estimate_prompt_tokens = true
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
