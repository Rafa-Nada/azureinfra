variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the virtual machine"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password for the virtual machine"
}

variable "db_username" {
  type        = string
  description = "MySQL admin username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "MySQL admin password"
}
