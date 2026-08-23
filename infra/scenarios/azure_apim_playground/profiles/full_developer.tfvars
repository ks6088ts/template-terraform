sku_name = "Developer_1"

backend_pool = {
  primary_weight               = 3
  secondary_weight             = 1
  session_affinity_cookie_name = "apim-playground-session"
  circuit_breaker = {
    failure_count      = 2
    interval_duration  = "PT1M"
    trip_duration      = "PT1M"
    accept_retry_after = true
  }
}

observability = {
  retention_in_days   = 30
  sampling_percentage = 100
  verbosity           = "information"
  log_client_ip       = false
}
