sku_name = "Developer_1"

observability = {
  retention_in_days   = 30
  sampling_percentage = 100
  verbosity           = "information"
  log_client_ip       = false
}

cost_showback = {
  business_units = {
    "bu-engineering" = "Engineering"
    "bu-finance"     = "Finance"
    "bu-hr"          = "Human Resources"
    "bu-marketing"   = "Marketing"
  }
  workbook_enabled                = true
  base_monthly_cost               = 150
  per_1000_requests_cost          = 0.003
  prompt_per_1000_tokens_cost     = 0.00025
  completion_per_1000_tokens_cost = 0.002
}
