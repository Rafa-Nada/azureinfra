variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string

  validation {
    condition     = length(var.prefix) > 2
    error_message = "Prefix must be at least 3 characters long."
  }
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sql_admin" {
  description = "SQL admin username"
  type        = string

  validation {
    condition     = length(var.sql_admin) >= 5
    error_message = "SQL admin username must be at least 5 characters long."
  }
}

variable "sql_password" {
  description = "SQL admin password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sql_password) >= 12
    error_message = "SQL password must be at least 12 characters long."
  }
}

variable "storage_account_name" {
  description = "Globally unique Storage Account name (3-24 lowercase letters/numbers)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string

  validation {
    condition     = can(regex("^[-0-9a-fA-F]{36}$", var.subscription_id))
    error_message = "Must be a valid Azure Subscription ID (GUID format)."
  }
}
