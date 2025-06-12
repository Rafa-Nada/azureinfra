variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique Storage Account name"
  type        = string
}

variable "sql_admin" {
  description = "SQL admin username"
  type        = string
}

variable "sql_password" {
  description = "SQL admin password"
  type        = string
  sensitive   = true
}
