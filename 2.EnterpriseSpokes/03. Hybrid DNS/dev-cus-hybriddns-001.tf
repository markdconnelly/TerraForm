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

#region Private DNS Zones
resource "azurerm_private_dns_zone" "zone-privatelink-global.wvd.microsoft.com" {
  name                = "privatelink-global.wvd.microsoft.com."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.database.windows.net" {
  name                = "privatelink.database.windows.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.mysql.database.azure.com" {
  name                = "privatelink.mysql.database.azure.com."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.redis.cache.windows.net" {
  name                = "privatelink.redis.cache.windows.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.redisenterprise.cache.azure.net" {
  name                = "privatelink.redisenterprise.cache.azure.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.his.arc.azure.com" {
  name                = "privatelink.his.arc.azure.com."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.guestconfiguration.azure.com" {
  name                = "privatelink.guestconfiguration.azure.com."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.servicebus.windows.net" {
  name                = "privatelink.servicebus.windows.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.eventgrid.azure.net" {
  name                = "privatelink.eventgrid.azure.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.azure-api.net" {
  name                = "privatelink.azure-api.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.azure-automation.net" {
  name                = "privatelink.azure-automation.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.cus.backup.windowsazure.com" {
  name                = "privatelink.cus.backup.windowsazure.com."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.eus2.backup.windowsazure.com" {
  name                = "privatelink.eus2.backup.windowsazure.com."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.siterecovery.windowsazure.com" {
  name                = "privatelink.siterecovery.windowsazure.com."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.monitor.azure.com" {
  name                = "privatelink.monitor.azure.com."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.oms.opinsights.azure.com" {
  name                = "privatelink.oms.opinsights.azure.com."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.ods.opinsights.azure.com" {
  name                = "privatelink.ods.opinsights.azure.com."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.agentsvc.azure-automation.net" {
  name                = "privatelink.agentsvc.azure-automation.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.vaultcore.azure.net" {
  name                = "privatelink.vaultcore.azure.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.blob.core.windows.net" {
  name                = "privatelink.blob.core.windows.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.table.core.windows.net" {
  name                = "privatelink.table.core.windows.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.queue.core.windows.net" {
  name                = "privatelink.queue.core.windows.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.file.core.windows.net" {
  name                = "privatelink.file.core.windows.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.web.core.windows.net" {
  name                = "privatelink.web.core.windows.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.dfs.core.windows.net" {
  name                = "privatelink.dfs.core.windows.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.afs.azure.net" {
  name                = "privatelink.afs.azure.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.search.windows.net" {
  name                = "privatelink.search.windows.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.azurewebsites.net" {
  name                = "privatelink.azurewebsites.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-scm.privatelink.azurewebsites.net" {
  name                = "scm.privatelink.azurewebsites.net."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.adf.azure.us" {
  name                = "privatelink.adf.azure.us."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}

resource "azurerm_private_dns_zone" "zone-privatelink.datafactory.azure.us" {
  name                = "privatelink.datafactory.azure.us."
  resource_group_name = azurerm_resource_group.ent_cus_hybriddns_rg.name
}




