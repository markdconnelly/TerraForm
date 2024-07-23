#region Building Blocks
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Ent_DevOps_DataPipeline-01_RG" {
  name     = "Ent_DevOps_DataPipeline-01_RG"
  location = "Central US"
          tags = {
        environment = "production"
        costcenter = "DevOps"
        description = "Resource group for general data pipeline services in the DevOps environment. Critical business operations are dependent on these pipelines."
    }
}

# Managed Identity for workload
# Key Vault for the workload
# Etc Building Blocks

#endregion

#region Network Block



#endregion

# Data Factory for the workload
resource "azurerm_data_factory" "adf-devops-dp-01" {
  name                = "adf-devops-dp-01"
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}

