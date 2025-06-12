provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# App Service Plan
resource "azurerm_app_service_plan" "asp" {
  name                = "${var.prefix}-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Basic"
    size = "B1"
  }
  kind = "Linux"
  reserved = true
}

resource "azurerm_app_service" "app" {
  name                = "${var.prefix}-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  app_settings = {
    "APP_ENV"                   = "production"
    "DOCKER_CUSTOM_IMAGE_NAME" = "ghost:alpine"
    "WEBSITES_PORT"            = "2368"

    # Optional: App Service settings if needed for logs, debugging, etc.
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }

  site_config {
    linux_fx_version = "DOCKER|ghost:alpine"
    always_on        = true
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_key_vault_secret.sql_admin_user,
    azurerm_key_vault_secret.sql_admin_pass
  ]
}


# SQL Server
resource "azurerm_mssql_server" "sql" {
  name                         = "${var.prefix}-sqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin
  administrator_login_password = var.sql_password
}

# SQL Database
resource "azurerm_mssql_database" "sqldb" {
  name                = "${var.prefix}-sqldb"
  server_id           = azurerm_mssql_server.sql.id
  sku_name            = "Basic"
  max_size_gb         = 2
  zone_redundant      = false
  auto_pause_delay_in_minutes = 60
  min_capacity        = 0.5
}
