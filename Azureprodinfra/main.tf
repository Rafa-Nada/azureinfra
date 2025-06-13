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
  version                = "8.0"
  zone                   = "1"
  storage_mb             = 32768
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false
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

  site_config {
    always_on = true
    application_stack {
      docker_image_name   = "ghost"
      docker_image_tag    = "alpine"
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = {
    "url" = "https://${var.prefix}-webapp.azurewebsites.net"

    # Ghost DB configuration
    "database__client"                   = "mysql"
    "database__connection__host"        = azurerm_mysql_flexible_server.mysql.fqdn
    "database__connection__user"        = "${var.sql_admin}@${azurerm_mysql_flexible_server.mysql.name}"
    "database__connection__password"    = var.sql_password
    "database__connection__database"    = azurerm_mysql_flexible_database.ghostdb.name

    "WEBSITES_PORT"                     = "2368"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "true"
  }

  identity {
    type = "SystemAssigned"
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
