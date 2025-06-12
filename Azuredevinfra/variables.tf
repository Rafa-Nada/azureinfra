variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "location" {
  type        = string
  default     = "East US"
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "prefix" {
  type        = string
  description = "Prefix for resource naming"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name (must be globally unique, lowercase, 3-24 chars)"
}

variable "sql_admin" {
  type        = string
  description = "SQL Server admin username"
}

variable "sql_password" {
  type        = string
  description = "SQL Server admin password"
  sensitive   = true
}
