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

# Create a user assigned managed identity to perform operations on behalf of the Data Pipeline
resource "azurerm_user_assigned_identity" "mgid-devops-datapipeline-01" {
  name                = "mgid-devops-datapipeline-01"
  location            = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}

# Key Vault for the workload
# Create an Azure Key Vault to store the certificate for deep packet inspection
resource "azurerm_key_vault" "kv-devops-datapipeline-01" {
  name                        = "kv-ent-vwan"
  location                    = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.location
  resource_group_name         = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name = "standard" 
  enable_rbac_authorization = true
  public_network_access_enabled = false
  network_acls {
    default_action = Deny
    bypass = AzureServices
  }
}
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

#region Data Factory
# Data Factory for the workload
resource "azurerm_data_factory" "adf-devops-dp-01" {
  name                = "adf-devops-dp-01"
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}
#endregion

#region Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "storageaccountname"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}


#endregion

#region Containers

#endregion

#region App Service Plan

#endregion

#region Function Apps

#endregion

#region Logic App

#endregion






