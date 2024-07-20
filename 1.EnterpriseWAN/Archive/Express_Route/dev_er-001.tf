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

# Create the resource groups required for the Express Route Circuits
resource "azurerm_resource_group" "Ent_ExpressRoutes_RG" {
    name     = "Ent_ExpressRoutes_RG"
    location = "Central US"
}

/* Create the Express Route Circuits:
1. Champaign's primary Express Route will be connected to the Central US region via Chicago, IL. This will provide the best network connectivity and Should be set to Unlimited. 
2. Champaign's secondary Express Route will be connected to the East US 2 region via Dallas, TX. This will provide the next best network connectivity and Should be set to Metered.
3. Atlanta's primary Express Route will connected to the Central US region via Atlanta, GA. This will provide the best network connectivity and Should be set to Unlimited. 
4. Atlanta's secondary Express Route will be connected to the East US 2 region via Miami, FL. This will provide the next best network connectivity and Should be set to Metered.
*/

resource "azurerm_express_route_circuit" "er-cmi-chi-cus-01" {
    name                = "er-cmi-chi-cus-01"
    location            = "chicago"
    resource_group_name = azurerm_resource_group.Ent_ExpressRoutes_RG.name
    bandwidth_in_mbps   = 10000
    sku {
        tier = "Standard"
        family = "UnlimitedData"
    }
}

resource "azurerm_express_route_circuit" "er-cmi-dal-eus-01" {
    name                = "er-cmi-dal-eus-01"
    location            = "dallas"
    resource_group_name = azurerm_resource_group.Ent_ExpressRoutes_RG.name
    bandwidth_in_mbps   = 10000
    sku {
        tier = "Standard"
        family = "MeteredData"
    }
}

resource "azurerm_express_route_circuit" "er-atl-atl-01" {
    name                = "er-atl-atl-01"
    location            = "atlanta"
    resource_group_name = azurerm_resource_group.Ent_ExpressRoutes_RG.name
    bandwidth_in_mbps   = 10000
    sku {
        tier = "Standard"
        family = "UnlimitedData"
    }
}

resource "azurerm_express_route_circuit" "er-atl-mia-01" {
    name                = "er-atl-mia-01"
    location            = "miami"
    resource_group_name = azurerm_resource_group.Ent_ExpressRoutes_RG.name
    bandwidth_in_mbps   = 10000
    sku {
        tier = "Standard"
        family = "MeteredData"
    }
}

# Create the Express Route Circuit Private Peerings
resource "azurerm_express_route_circuit_peering" "er-cmi-chi-cus-01-prvpeer" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.er-cmi-chi-cus-01.name
  resource_group_name           = azurerm_resource_group.Ent_ExpressRoutes_RG.name
  shared_key                    = "ItsASecret"
  peer_asn                      = 65656
  primary_peer_address_prefix   = "192.168.1.0/30"
  secondary_peer_address_prefix = "192.168.2.0/30"
  vlan_id                       = 87
}

resource "azurerm_express_route_circuit_peering" "er-cmi-dal-eus-01-prvpeer" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.er-champaign-chicago-cus-01.name
  resource_group_name           = azurerm_resource_group.Ent_ExpressRoutes_RG.name
  shared_key                    = "ItsASecret"
  peer_asn                      = 65656
  primary_peer_address_prefix   = "192.168.3.0/30"
  secondary_peer_address_prefix = "192.168.4.0/30"
  vlan_id                       = 92
}

resource "azurerm_express_route_circuit_peering" "er-cmi-dal-eus-01-prvpeer" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.er-champaign-chicago-cus-01.name
  resource_group_name           = azurerm_resource_group.Ent_ExpressRoutes_RG.name
  shared_key                    = "ItsASecret"
  peer_asn                      = 65656
  primary_peer_address_prefix   = "192.168.3.0/30"
  secondary_peer_address_prefix = "192.168.4.0/30"
  vlan_id                       = 92
}

resource "azurerm_express_route_circuit_peering" "er-atl-atl-01-prvpeer" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.er-atl-atl-01.name
  resource_group_name           = azurerm_resource_group.Ent_ExpressRoutes_RG.name
  shared_key                    = "ItsASecret"
  peer_asn                      = 65656
  primary_peer_address_prefix   = "192.168.5.0/30"
  secondary_peer_address_prefix = "192.168.6.0/30"
  vlan_id                       = 35
}

resource "azurerm_express_route_circuit_peering" "er-atl-mia-01-prvpeer" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.er-atl-mia-01.name
  resource_group_name           = azurerm_resource_group.Ent_ExpressRoutes_RG.name
  shared_key                    = "ItsASecret"
  peer_asn                      = 65656
  primary_peer_address_prefix   = "192.168.7.0/30"
  secondary_peer_address_prefix = "192.168.8.0/30"
  vlan_id                       = 17
}




resource "azurerm_express_route_circuit_connection" "connection_1" {
    name                      = "connection_1"
    resource_group_name       = "your_resource_group_name"
    express_route_circuit_name = azurerm_express_route_circuit.express_route_1.name
    peer_express_route_circuit_id = azurerm_express_route_circuit.express_route_gateway_central.id
}

resource "azurerm_express_route_circuit_connection" "connection_2" {
    name                      = "connection_2"
    resource_group_name       = "your_resource_group_name"
    express_route_circuit_name = azurerm_express_route_circuit.express_route_2.name
    peer_express_route_circuit_id = azurerm_express_route_circuit.express_route_gateway_east.id
}

resource "azurerm_express_route_circuit_connection" "connection_3" {
    name                      = "connection_3"
    resource_group_name       = "your_resource_group_name"
    express_route_circuit_name = azurerm_express_route_circuit.express_route_3.name
    peer_express_route_circuit_id = azurerm_express_route_circuit.express_route_gateway_central.id
}

resource "azurerm_express_route_circuit_connection" "connection_4" {
    name                      = "connection_4"
    resource_group_name       = "your_resource_group_name"
    express_route_circuit_name = azurerm_express_route_circuit.express_route_4.name
    peer_express_route_circuit_id = azurerm_express_route_circuit.express_route_gateway_east.id
}

resource "azurerm_express_route_gateway" "express_route_gateway_central" {
    name                = "express_route_gateway_central"
    location            = "centralus"
    resource_group_name = "your_resource_group_name"
    sku                 = "Standard"
}

resource "azurerm_express_route_gateway" "express_route_gateway_east" {
    name                = "express_route_gateway_east"
    location            = "eastus2"
    resource_group_name = "your_resource_group_name"
    sku                 = "Standard"
}