variable "account_id" {
  description = "ID of the existing Cloudflare account to read"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must contain exactly 32 lowercase hexadecimal characters."
  }
}
