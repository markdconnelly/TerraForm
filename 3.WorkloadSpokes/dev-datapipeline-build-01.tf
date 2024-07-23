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

#region CUS Network Block
resource "azurerm_virtual_network" "vnet-cus-datapipeline-01" {
  name                = "vnet-cus-datapipeline-01"
  address_space       = ["172.16.100.0/24"]
  dns_servers = [ "172.16.0.6","172.16.0.7","172.17.0.6" ]
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}


resource "azurerm_subnet" "subnet-cus-datapipeline-01-default" {
  name                 = "subnet-cus-datapipeline-01-default"
  resource_group_name  = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
  virtual_network_name = azurerm_virtual_network.vnet-cus-datapipeline-01.name
  address_prefixes     = ["172.16.100.0/24"]
}

resource "azurerm_network_security_group" "nsg-cus-datapipeline-01" {
  name                = "nsg-cus-datapipeline-01"
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}
#endregion

#region EUS 2 Network Block
resource "azurerm_virtual_network" "vnet-eus-datapipeline-01" {
  name                = "vnet-eus-datapipeline-01"
  address_space       = ["172.17.100.0/24"]
  dns_servers = [ "172.17.0.6","172.17.0.7","172.16.0.6" ]
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}


resource "azurerm_subnet" "subnet-eus-datapipeline-01-default" {
  name                 = "subnet-eus-datapipeline-01-default"
  resource_group_name  = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
  virtual_network_name = azurerm_virtual_network.vnet-eus-datapipeline-01.name
  address_prefixes     = ["172.17.100.0/24"]
}

resource "azurerm_network_security_group" "nsg-eus-datapipeline-01" {
  name                = "nsg-eus-datapipeline-01"
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}

#endregion

# Data Factory for the workload
resource "azurerm_data_factory" "adf-devops-dp-01" {
  name                = "adf-devops-dp-01"
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}

