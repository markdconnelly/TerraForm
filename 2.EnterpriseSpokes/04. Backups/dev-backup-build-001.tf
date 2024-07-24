#region Building Blocks
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Ent_SecOps_Backups_RG" {
  name     = "Ent_SecOps_Backups_RG"
  location = "Central US"
          tags = {
        environment = "production"
        costcenter = "Security Operations"
        description = "Resource group for backup services in the Security Operations environment"
    }
}

resource "azurerm_resource_group" "Ent_IT_Backups_RG" {
  name     = "Ent_IT_Backups_RG"
  location = "Central US"
          tags = {
        environment = "production"
        costcenter = "IT"
        description = "Resource group for backup services in the IT environment"
    }
}

resource "azurerm_resource_group" "Ent_DevOps_Backups_RG" {
  name     = "Ent_DevOps_Backups_RG"
  location = "Central US"
          tags = {
        environment = "production"
        costcenter = "DevOps"
        description = "Resource group for backup services in the DevOps environment"
    }
}
