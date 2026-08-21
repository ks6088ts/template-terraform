variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "azureapimplayground"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "japaneast"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    scenario        = "azure_apim_playground"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

variable "publisher_name" {
  description = "Publisher name for the API Management instance"
  type        = string
  default     = "Example Organization"
}

variable "publisher_email" {
  description = "Publisher email for the API Management instance"
  type        = string
  default     = "admin@example.com"
}

variable "sku_name" {
  description = "SKU tier and capacity for API Management; Consumption_0 keeps this playground serverless and usage-based"
  type        = string
  default     = "Consumption_0"
}

variable "core_rate_limit" {
  description = "Subscription rate limit for the self-contained core API"
  type = object({
    calls                  = optional(number, 5)
    renewal_period_seconds = optional(number, 60)
  })
  default = {}

  validation {
    condition     = var.core_rate_limit.calls >= 1 && var.core_rate_limit.calls <= 1000
    error_message = "core_rate_limit.calls must be between 1 and 1000."
  }

  validation {
    condition     = var.core_rate_limit.renewal_period_seconds >= 1 && var.core_rate_limit.renewal_period_seconds <= 300
    error_message = "core_rate_limit.renewal_period_seconds must be between 1 and 300."
  }
}

variable "backend_pool" {
  description = "Optional deterministic Container Apps backends and APIM load-balancing configuration"
  type = object({
    container_image              = optional(string, "mendhak/http-https-echo:41")
    primary_weight               = optional(number, 3)
    secondary_weight             = optional(number, 1)
    session_affinity_cookie_name = optional(string)
    circuit_breaker = optional(object({
      failure_count      = optional(number, 2)
      interval_duration  = optional(string, "PT1M")
      trip_duration      = optional(string, "PT1M")
      accept_retry_after = optional(bool, true)
    }))
  })
  default = null

  validation {
    condition = var.backend_pool == null || alltrue([
      var.backend_pool.primary_weight >= 1,
      var.backend_pool.primary_weight <= 100,
      var.backend_pool.secondary_weight >= 1,
      var.backend_pool.secondary_weight <= 100,
    ])
    error_message = "backend_pool weights must be between 1 and 100."
  }

  validation {
    condition     = var.backend_pool == null || var.backend_pool.session_affinity_cookie_name == null || can(regex("^[A-Za-z0-9_-]+$", var.backend_pool.session_affinity_cookie_name))
    error_message = "backend_pool.session_affinity_cookie_name may contain only letters, numbers, underscores, and hyphens."
  }

  validation {
    condition     = var.backend_pool == null || try(var.backend_pool.circuit_breaker.failure_count >= 1 && var.backend_pool.circuit_breaker.failure_count <= 10000, true)
    error_message = "backend_pool.circuit_breaker.failure_count must be between 1 and 10000."
  }
}

variable "ai_backend" {
  description = "Optional OpenAI v1 backend, either provisioned by this scenario or referenced as an existing Azure AI resource"
  type = object({
    provision = optional(object({
      format          = optional(string, "OpenAI")
      deployment_name = string
      model           = string
      version         = string
      sku_name        = optional(string, "GlobalStandard")
      capacity        = optional(number, 50)
    }))
    existing = optional(object({
      endpoint        = string
      resource_id     = string
      deployment_name = string
    }))
  })
  default = null

  validation {
    condition = var.ai_backend == null || (
      (try(var.ai_backend.provision, null) != null) !=
      (try(var.ai_backend.existing, null) != null)
    )
    error_message = "ai_backend must set exactly one of provision or existing."
  }

  validation {
    condition     = var.ai_backend == null || try(var.ai_backend.provision.capacity > 0, true)
    error_message = "ai_backend.provision.capacity must be greater than zero."
  }

  validation {
    condition     = var.ai_backend == null || try(var.ai_backend.existing, null) == null || can(regex("^https://.+/openai/v1/?$", var.ai_backend.existing.endpoint))
    error_message = "ai_backend.existing.endpoint must be an HTTPS OpenAI v1 base URL ending in /openai/v1."
  }

  validation {
    condition     = var.ai_backend == null || try(var.ai_backend.existing, null) == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+$", var.ai_backend.existing.resource_id))
    error_message = "ai_backend.existing.resource_id must be a Microsoft.CognitiveServices account resource ID."
  }
}

variable "llm_token_limit" {
  description = "Optional LLM token rate limit and quota policy; requires ai_backend and a non-Consumption APIM SKU"
  type = object({
    tokens_per_minute      = optional(number)
    token_quota            = optional(number)
    token_quota_period     = optional(string, "Monthly")
    estimate_prompt_tokens = optional(bool, false)
  })
  default = null

  validation {
    condition = var.llm_token_limit == null || (
      var.llm_token_limit.tokens_per_minute != null ||
      var.llm_token_limit.token_quota != null
    )
    error_message = "llm_token_limit must specify tokens_per_minute, token_quota, or both."
  }

  validation {
    condition     = var.llm_token_limit == null || try(var.llm_token_limit.tokens_per_minute > 0, true)
    error_message = "llm_token_limit.tokens_per_minute must be greater than zero."
  }

  validation {
    condition     = var.llm_token_limit == null || try(var.llm_token_limit.token_quota > 0, true)
    error_message = "llm_token_limit.token_quota must be greater than zero."
  }

  validation {
    condition     = var.llm_token_limit == null || contains(["Hourly", "Daily", "Weekly", "Monthly", "Yearly"], var.llm_token_limit.token_quota_period)
    error_message = "llm_token_limit.token_quota_period must be Hourly, Daily, Weekly, Monthly, or Yearly."
  }
}

variable "content_safety" {
  description = "Optional Azure AI Content Safety policy and backend configuration; requires ai_backend and a non-Consumption APIM SKU"
  type = object({
    provision = optional(object({
      sku_name = optional(string, "S0")
    }))
    existing = optional(object({
      endpoint    = string
      resource_id = string
    }))
    shield_prompt          = optional(bool, true)
    enforce_on_completions = optional(bool, false)
    blocklist_name         = optional(string, "apim-playground")
    categories = optional(map(number), {
      Hate     = 4
      SelfHarm = 4
      Sexual   = 4
      Violence = 4
    })
  })
  default = null

  validation {
    condition = var.content_safety == null || (
      (try(var.content_safety.provision, null) != null) !=
      (try(var.content_safety.existing, null) != null)
    )
    error_message = "content_safety must set exactly one of provision or existing."
  }

  validation {
    condition     = var.content_safety == null || try(var.content_safety.provision, null) == null || contains(["F0", "S0"], var.content_safety.provision.sku_name)
    error_message = "content_safety.provision.sku_name must be F0 or S0."
  }

  validation {
    condition     = var.content_safety == null || try(var.content_safety.existing, null) == null || can(regex("^https://[^/]+\\.cognitiveservices\\.azure\\.com/?$", var.content_safety.existing.endpoint))
    error_message = "content_safety.existing.endpoint must be an HTTPS cognitiveservices.azure.com endpoint."
  }

  validation {
    condition     = var.content_safety == null || try(var.content_safety.existing, null) == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+$", var.content_safety.existing.resource_id))
    error_message = "content_safety.existing.resource_id must be a Microsoft.CognitiveServices account resource ID."
  }

  validation {
    condition = var.content_safety == null || alltrue([
      for name, threshold in var.content_safety.categories :
      contains(["Hate", "SelfHarm", "Sexual", "Violence"], name) && threshold >= 0 && threshold <= 7
    ])
    error_message = "content_safety categories must be Hate, SelfHarm, Sexual, or Violence with thresholds from 0 through 7."
  }

  validation {
    condition     = var.content_safety == null || can(regex("^[A-Za-z0-9._~-]+$", var.content_safety.blocklist_name))
    error_message = "content_safety.blocklist_name contains unsupported characters."
  }
}

variable "observability" {
  description = "Optional Log Analytics and managed-identity Application Insights integration for API Management"
  type = object({
    retention_in_days   = optional(number, 30)
    sampling_percentage = optional(number, 100)
    verbosity           = optional(string, "information")
    log_client_ip       = optional(bool, false)
    llm_logging = optional(object({
      log_prompts               = optional(bool, false)
      log_completions           = optional(bool, false)
      max_message_size_in_bytes = optional(number, 32768)
    }))
  })
  default = null

  validation {
    condition     = var.observability == null || (var.observability.retention_in_days >= 30 && var.observability.retention_in_days <= 730)
    error_message = "observability.retention_in_days must be between 30 and 730."
  }

  validation {
    condition     = var.observability == null || (var.observability.sampling_percentage >= 0 && var.observability.sampling_percentage <= 100)
    error_message = "observability.sampling_percentage must be between 0 and 100."
  }

  validation {
    condition     = var.observability == null || contains(["error", "information", "verbose"], var.observability.verbosity)
    error_message = "observability.verbosity must be error, information, or verbose."
  }

  validation {
    condition     = var.observability == null || try(var.observability.llm_logging.max_message_size_in_bytes >= 1 && var.observability.llm_logging.max_message_size_in_bytes <= 262144, true)
    error_message = "observability.llm_logging.max_message_size_in_bytes must be between 1 and 262144."
  }
}

variable "llm_token_metrics" {
  description = "Optional preview LLM token metrics emitted to Application Insights; requires ai_backend and observability"
  type = object({
    namespace = optional(string, "APIM Playground")
    dimensions = optional(list(string), [
      "API ID",
      "Subscription ID",
    ])
  })
  default = null

  validation {
    condition     = var.llm_token_metrics == null || can(regex("^[A-Za-z0-9 ._-]+$", var.llm_token_metrics.namespace))
    error_message = "llm_token_metrics.namespace may contain only letters, numbers, spaces, periods, underscores, and hyphens."
  }

  validation {
    condition = var.llm_token_metrics == null || (
      length(var.llm_token_metrics.dimensions) >= 1 &&
      length(var.llm_token_metrics.dimensions) <= 5 &&
      length(distinct(var.llm_token_metrics.dimensions)) == length(var.llm_token_metrics.dimensions) &&
      alltrue([
        for dimension in var.llm_token_metrics.dimensions : contains([
          "API ID",
          "Operation ID",
          "Product ID",
          "User ID",
          "Subscription ID",
          "Location",
          "Gateway ID",
          "Backend ID",
        ], dimension)
      ])
    )
    error_message = "llm_token_metrics.dimensions must contain one to five unique documented default dimension names."
  }
}

variable "operator_principal_id" {
  description = "Object ID of the principal that runs data-plane setup scripts; defaults to the Terraform client principal"
  type        = string
  default     = null
}
