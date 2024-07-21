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

# Create the resource groups required for the Entreprise Virtual WAN
resource "azurerm_resource_group" "Ent_vWAN_RG" {
    name     = "Ent_vWAN_RG"
    location = "Central US"
        tags = {
        environment = "production"
        costcenter = "IT"
        description = "Resource group for the Enterprise Virtual WAN"
    }
}

#endregion