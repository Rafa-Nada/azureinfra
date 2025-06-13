provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

# --------------------
# Resource Group
# --------------------
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
# Azure Storage Account
# --------------------
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# --------------------
# MySQL Flexible Server
# --------------------
resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "${var.prefix}-mysql"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  administrator_login    = var.sql_admin
  administrator_password = var.sql_password
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  zone                   = "1"
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false

  storage {
    size_gb = 32
  }
}


resource "azurerm_mysql_flexible_database" "ghostdb" {
  name                = "${var.prefix}db"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# --------------------
# App Service Plan
# --------------------
resource "azurerm_service_plan" "asp" {
  name                = "${var.prefix}-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "S1"
}

# --------------------
# Linux Web App (Ghost in Docker)
# --------------------
resource "azurerm_linux_web_app" "app" {
  name                = "${var.prefix}-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      docker_image_name = "ghost"
      docker_image_tag  = "alpine"
    }

    always_on = true
  }

  app_settings = {
    "APP_ENV"                            = "production"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                      = "2368"
  }

  depends_on = [
    azurerm_key_vault_secret.sql_admin_user,
    azurerm_key_vault_secret.sql_admin_pass
  ]
}


# --------------------
# Key Vault Access Policy for App
# --------------------
resource "azurerm_key_vault_access_policy" "app_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.app.identity.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}
