terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "${var.prefix}-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
}

resource "azurerm_key_vault_secret" "sql_admin_user" {
  name         = "SqlAdminUsername"
  value        = var.sql_admin
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "sql_admin_pass" {
  name         = "SqlAdminPassword"
  value        = var.sql_password
  key_vault_id = azurerm_key_vault.kv.id
}

# Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# SQL Server & DB
resource "azurerm_mssql_server" "sql" {
  name                         = "${var.prefix}-sqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin
  administrator_login_password = var.sql_password
}

resource "azurerm_mssql_database" "sqldb" {
  name           = "${var.prefix}-sqldb"
  server_id      = azurerm_mssql_server.sql.id
  sku_name       = "S1"
  max_size_gb    = 10
  zone_redundant = false
}

# App Service Plan (Linux)
resource "azurerm_service_plan" "asp" {
  name                = "${var.prefix}-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "S1"
}

# Linux Web App with Docker container
resource "azurerm_linux_web_app" "app" {
  name                = "${var.prefix}-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true
  }

  app_service_container {
    image_name = "ghost"
    image_tag  = "alpine"
  }

  app_settings = {
    "APP_ENV"                             = "production"
    "WEBSITES_PORT"                      = "2368"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }

  depends_on = [
    azurerm_key_vault_secret.sql_admin_user,
    azurerm_key_vault_secret.sql_admin_pass
  ]
}

# Key Vault Access Policy for Web App
resource "azurerm_key_vault_access_policy" "app_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.app.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}
