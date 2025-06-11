variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure location"
  default     = "East US"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account (must be globally unique, lowercase only)"
}

variable "app_service_plan_name" {
  type        = string
  description = "The name of the app service plan"
}

variable "function_app_name" {
  type        = string
  description = "The name of the Function App"
}

variable "runtime" {
  type        = string
  description = "Function App runtime: dotnet, node, python, etc."
  default     = "dotnet"
}
