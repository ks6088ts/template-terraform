variable "length" {
  description = "The length of the random string"
  type        = number
  default     = 5
}

variable "min_numeric" {
  description = "Minimum number of numeric characters in the result"
  type        = number
  default     = 5
}

variable "numeric" {
  description = "Include numeric characters in the result"
  type        = bool
  default     = true
}

variable "special" {
  description = "Include special characters in the result"
  type        = bool
  default     = false
}

variable "lower" {
  description = "Include lowercase alphabet characters in the result"
  type        = bool
  default     = true
}

variable "upper" {
  description = "Include uppercase alphabet characters in the result"
  type        = bool
  default     = false
}
