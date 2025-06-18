variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B1s"
}
