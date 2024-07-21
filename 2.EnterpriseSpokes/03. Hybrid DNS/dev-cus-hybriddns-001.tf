#region BuldingBlocks
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Ent_CUS_HybridDNS_RG" {
  name     = "Ent_CUS_HybridDNS_RG"
  location = "Central US"
          tags = {
        environment = "production"
        costcenter = "IT"
        description = "Resource group for Enterprise hybrid DNS services"
    }
}

#endregion

#region Network
resource "azurerm_virtual_network" "vnet-cus-hybriddns-01" {
  name                = "vnet-cus-hybriddns-01"
  address_space       = ["172.16.1.0/24"]
  dns_servers = [ "172.16.0.6","172.16.0.7","172.17.0.6" ]
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_CUS_HybridDNS_RG.name
}


resource "azurerm_subnet" "subnet-cus-hybriddns-inbound" {
  name                 = "subnet-cus-hybriddns-inbound"
  resource_group_name  = azurerm_resource_group.Ent_CUS_HybridDNS_RG
  virtual_network_name = azurerm_virtual_network.vnet-cus-hybriddns-01.name
  address_prefixes     = ["172.16.1.0/25"]
  delegation {
  name = "Microsoft.Network.dnsResolvers"
  service_delegation {
    actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_subnet" "subnet-cus-hybriddns-outbound" {
  name                 = "subnet-cus-hybriddns-outbound"
  resource_group_name  = azurerm_resource_group.Ent_CUS_HybridDNS_RG
  virtual_network_name = azurerm_virtual_network.vnet-cus-hybriddns-01.name
  address_prefixes     = ["172.16.1.128/25"]
    delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}


resource "azurerm_network_security_group" "nsg-cus-hybriddns-01" {
  name                = "nsg-cus-hybriddns-01"
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}