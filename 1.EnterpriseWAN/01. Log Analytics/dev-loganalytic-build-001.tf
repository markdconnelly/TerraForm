#region BuildingBlocks
# Declate Azure as the resource provider via hashicorp/azurerm
terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = ">= 2.0"
        }
    }
}

provider "azurerm" {
    features {}
}

# Create the resource groups required for the Entreprise Log Analytics services
resource "azurerm_resource_group" "Ent_Sentinel_RG" {
    name     = "Ent_Sentinel_RG"
    location = "Central US"
        tags = {
        environment = "production"
        costcenter = "Security Operations"
        description = "Resource group for the Enterprise Security log analytics services"
    }
}

resource "azurerm_resource_group" "Ent_IT_LAW_RG" {
    name     = "Ent_IT_LAW_RG"
    location = "Central US"
        tags = {
        environment = "production"
        costcenter = "IT"
        description = "Resource group for the IT log analytics services"
    }
}

resource "azurerm_resource_group" "Ent_DevOps_LAW_RG" {
    name     = "Ent_DevOps_LAW_RG"
    location = "Central US"
        tags = {
        environment = "production"
        costcenter = "DevOps"
        description = "Resource group for the DevOps log analytics services"
    }
}
#endregion

# Create the Log Analytics workspace for the Enterprise services

resource "azurerm_log_analytics_workspace" "law-sentinel-cus-01" {
  name                = "law-sentinel-cus-01"
  location            = "Central US"
  resource_group_name = azurerm_resource_group.Ent_Sentinel_RG.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_workspace" "law-itops-cus-01" {
  name                = "law-itops-cus-01"
  location            = "Central US"
  resource_group_name = azurerm_resource_group.Ent_IT_LAW_RG.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_workspace" "law-devops-cus-01" {
  name                = "law-devops-cus-01"
  location            = "Central US"
  resource_group_name = azurerm_resource_group.Ent_DevOps_LAW_RG.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}