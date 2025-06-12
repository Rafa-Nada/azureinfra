provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# --------------------
# Azure Key Vault
# --------------------
resource "azurerm_key_vault" "kv" {
  name                        = "${var.prefix}-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
}

data "azurerm_client_config" "current" {}

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

# --------------------
# Storage Account
# --------------------
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# --------------------
# SQL Server + Database
# --------------------
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

# --------------------
# App Service Plan + App Service
# --------------------
resource "azurerm_app_service_plan" "asp" {
  name                = "${var.prefix}-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "S1"
  }

  kind     = "Linux"
  reserved = true
}

resource "azurerm_app_service" "app" {
  name                = "${var.prefix}-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  site_config {
    linux_fx_version = "DOTNETCORE|6.0"
  }

  app_settings = {
    "APP_ENV"                      = "production"
    "SQL_ADMIN_USERNAME"           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sql_admin_user.id})"
    "SQL_ADMIN_PASSWORD"           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sql_admin_pass.id})"
    "WEBSITE_RUN_FROM_PACKAGE"     = "1"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_key_vault_secret.sql_admin_user]
}

# --------------------
# Key Vault Access Policy for App
# --------------------
resource "azurerm_key_vault_access_policy" "app_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = object_id = azurerm_app_service.app.identity[0].principal_id

  secret_permissions = [
    "get", "list"
  ]
}
