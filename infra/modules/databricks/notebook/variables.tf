variable "path" {
  description = "Absolute Workspace notebook path, without empty, dot, or parent-directory segments or a trailing slash"
  type        = string
  nullable    = false

  validation {
    condition = startswith(var.path, "/") && !can(regex("[\\r\\n]", var.path)) && alltrue([
      for segment in split("/", trimprefix(var.path, "/")) : !contains(["", ".", ".."], segment)
    ])
    error_message = "Notebook path must be absolute, contain no empty, dot, or parent-directory segments or line breaks, and not end with a slash."
  }
}

variable "language" {
  description = "Notebook source language: SQL, PYTHON, SCALA, or R"
  type        = string
  nullable    = false

  validation {
    condition     = contains(["SQL", "PYTHON", "SCALA", "R"], var.language)
    error_message = "Notebook language must be SQL, PYTHON, SCALA, or R."
  }
}

variable "content_base64" {
  description = "Base64-encoded non-empty UTF-8 notebook source, including Databricks source-format cell separators when needed"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("\\S", base64decode(var.content_base64)))
    error_message = "Notebook content must be base64-encoded, non-empty UTF-8 source."
  }
}
