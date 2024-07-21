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

#endregion

#region DNS Resolver
resource "azurerm_private_dns_resolver" "dns-cus-hybriddns-01" {
  name                = "dns-cus-hybriddns-01"
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  virtual_network_id  = azurerm_virtual_network.vnet-cus-hybriddns-01.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "dns-cus-hybriddns-01-inbound" {
  name                    = "dns-cus-hybriddns-01-inbound"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns-cus-hybriddns-01.id
  location                = azurerm_virtual_wan_hub.vHub-CUS-01.location
  ip_configurations {
    private_ip_allocation_method = "Static"
    private_ip_address          = "172.16.1.6"
    subnet_id                    = azurerm_subnet.subnet-cus-hybriddns-inbound.id
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "dns-cus-hybriddns-01-outbound" {
  name                    = "dns-cus-hybriddns-01-outbound"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns-cus-hybriddns-01.id
  location                = azurerm_virtual_wan_hub.vHub-CUS-01.location
  subnet_id               = azurerm_subnet.subnet-cus-hybriddns-outbound.id
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "dnsfwd-cus-onprem-ruleset" {
  name                                       = "dnsfwd-cus-onprem-ruleset"
  resource_group_name                        = azurerm_resource_group.ent_cus_hybriddns_rg.name
  location                                   = azurerm_virtual_wan_hub.vHub-CUS-01.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.dns-cus-hybriddns-01-outbound.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "fwdrule-cus-onprem-com" {
  name                      = "fwdrule-cus-onprem-com"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.dnsfwd-cus-onprem-ruleset.id
  domain_name               = "onprem.com."
  enabled                   = true
  target_dns_servers {
    ip_address = ["172.16.0.6", "172.16.0.7", "172.17.0.6"]
    port       = 53

  }
}