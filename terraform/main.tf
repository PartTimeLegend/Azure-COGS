provider "azurerm" {
    version         = "= 2.33.0"
    features {}
}
locals {
    az_region_abbrv = var.az_region_abbr_map[var.az_region]
}

resource "azurerm_resource_group" "rgcogs" {
  name     = "rgcogs${local.az_region_abbrv}"
  location = var.az_region
}

resource "azurerm_automation_account" "aaacogs" {
  name                = "aaacogs${local.az_region_abbrv}"
  location            = var.az_region
  resource_group_name = azurerm_resource_group.rgcogs.name
  sku_name = "Basic"
  depends_on = [
    azurerm_resource_group.rgcogs
  ]
}

data "local_file" "runner_file" {
  filename = "../Runner.ps1"
}

resource "azurerm_automation_runbook" "arcogs" {
  name                    = "arcogs${local.az_region_abbrv}"
  location                = var.az_region
  resource_group_name     = azurerm_resource_group.rgcogs.name
  automation_account_name = azurerm_automation_account.aaacogs.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Starts and Stops Resources based on times"
  runbook_type            = "PowerShell"
  content = data.local_file.runner_file.content
  depends_on = [
    azurerm_resource_group.rgcogs,
    azurerm_automation_account.aaacogs,
    data.local_file.runner_file
  ]
  publish_content_link {
    uri = "https://www.microsoft.com" # Placeholder as Azure is dumb
  }
}
output "runbook_content" {
  value = data.local_file.runner_file.content
}