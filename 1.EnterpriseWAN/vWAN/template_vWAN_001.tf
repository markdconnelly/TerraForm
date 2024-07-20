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

#region VirtualWAN
# Create the Virtual WAN
resource "azurerm_virtual_wan" "vWAN-Enterprise-Services" {
    name                = "vWAN-Enterprise-Services"
    location            = "Central US"
    resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
}

# Create the Virtual WAN Hubs
resource "azurerm_virtual_wan_hub" "vHub-CUS-01" {
    name                = "vHub-CUS-01"
    virtual_wan_name    = azurerm_virtual_wan.vWAN-Enterprise-Services.name
    resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
}

resource "azurerm_virtual_wan_hub" "vHub-EUS-01" {
    name                = "vHub-EUS-01"
    virtual_wan_name    = azurerm_virtual_wan.vWAN-Enterprise-Services.name
    resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
}

# Create the firewall policy for the Virtual WAN
resource "azurerm_firewall_policy" "azfw-policy-vwan" {
  name                = "azfw-policy-vwan"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

# Create the Virtual WAN Hub Firewalls in each region
resource "azurerm_firewall" "azfw-cus-01" {
  name                = "azfw-cus-01"
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  sku_name            = "AZFW_Hub"
  sku_tier            = "Premium"
  firewall_policy_id = azurerm_firewall_policy.azfw-policy-vwan.id

  virtual_hub {
    virtual_hub_id  = azurerm_virtual_hub.vHub-CUS-01.id
    public_ip_count = 1
  }
}

resource "azurerm_firewall" "azfw-eus-01" {
  name                = "azfw-eus-01"
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  sku_name            = "AZFW_Hub"
  sku_tier            = "Premium"
  firewall_policy_id = azurerm_firewall_policy.azfw-policy-vwan.id

  virtual_hub {
    virtual_hub_id  = azurerm_virtual_hub.vHub-CUS-01.id
    public_ip_count = 1
  }
}

# Set routing intent up for each region
resource "azurerm_virtual_hub_routing_intent" "routeintent-cus" {
  name           = "routeintent-cus"
  virtual_hub_id = azurerm_virtual_hub.vHub-CUS-01.id

  routing_policy {
    name         = "InternetTrafficPolicy"
    destinations = ["Internet"]
    next_hop     = azurerm_firewall.azfw-cus-01.id
  }
  routing_policy {
    name         = "OnPremTrafficPolicy"
    destinations = ["OnPrem"]
    next_hop     = azurerm_firewall.azfw-cus-01.id
  }
}

resource "azurerm_virtual_hub_routing_intent" "touteintent-eus" {
  name           = "routeintent-eus"
  virtual_hub_id = azurerm_virtual_hub.vHub-EUS-01.id

  routing_policy {
    name         = "InternetTrafficPolicy"
    destinations = ["Internet"]
    next_hop     = azurerm_firewall.azfw-eus-01.id
  }
  routing_policy {
    name         = "OnPremTrafficPolicy"
    destinations = ["OnPrem"]
    next_hop     = azurerm_firewall.azfw-eus-01.id
  }
}
#endregion

#region ExpressRoute
# Create Express Route Gateways in each region
# Note that scale units are set to correspond to the throughput and the failover design. In this case 5 scale units is the recommended value for 10Gbps throughput.
# Each circuit in this instance can do 10G but not at the same time. The backup circuits at each location are metered in this example. 
resource "azurerm_express_route_gateway" "ergw-vwan-cus-01" {
  name                = "ergw-vwan-cus-01"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  location            = azurerm_virtual_hub.vHub-CUS-01.location
  virtual_hub_id      = azurerm_virtual_hub.vHub-CUS-01.id
  scale_units         = 5
}

resource "azurerm_express_route_gateway" "ergw-vwan-eus-01" {
  name                = "ergw-vwan-eus-01"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  location            = azurerm_virtual_hub.vHub-EUS-01.location
  virtual_hub_id      = azurerm_virtual_hub.vHub-EUS-01.id
  scale_units         = 5
}

/* Create the Express Route Circuits:
1. Champaign's primary Express Route will be connected to the Central US region via Chicago, IL. This will provide the best network connectivity and Should be set to Unlimited. 
2. Champaign's secondary Express Route will be connected to the East US 2 region via Dallas, TX. This will provide the next best network connectivity and Should be set to Metered.
3. Atlanta's primary Express Route will connected to the Central US region via Atlanta, GA. This will provide the best network connectivity and Should be set to Unlimited. 
4. Atlanta's secondary Express Route will be connected to the East US 2 region via Miami, FL. This will provide the next best network connectivity and Should be set to Metered.
*/

#First, set the intermediry objects for the Express Route Circuits
resource "azurerm_express_route_port" "example" {
  name                = "er-port-cus-chi-01"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  location            = azurerm_virtual_hub.vHub-CUS-01.location
  peering_location    = "MegaPort"
  bandwidth_in_gbps   = 10
  encapsulation       = "Dot1Q"
}

resource "azurerm_express_route_port" "example" {
  name                = "er-port-cus-dal-01"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  location            = azurerm_virtual_hub.vHub-CUS-01.location
  peering_location    = "AT&T"
  bandwidth_in_gbps   = 10
  encapsulation       = "Dot1Q"
}

resource "azurerm_express_route_port" "example" {
  name                = "er-port-eus-atl-01"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  location            = azurerm_virtual_hub.vHub-EUS-01.location
  peering_location    = "MegaPort"
  bandwidth_in_gbps   = 10
  encapsulation       = "Dot1Q"
}

resource "azurerm_express_route_port" "example" {
  name                = "er-port-eus-mia-01"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  location            = azurerm_virtual_hub.vHub-EUS-01.location
  peering_location    = "AT&T"
  bandwidth_in_gbps   = 10
  encapsulation       = "Dot1Q"
}

# Create the port authorization objects
resource "azurerm_express_route_port_authorization" "example" {
  name                    = "prtauth-cus-chi-01"
  express_route_port_name = azurerm_express_route_port.er-port-cus-chi-01.name
  resource_group_name     = azurerm_resource_group.Ent_vWAN_RG
}

resource "azurerm_express_route_port_authorization" "example" {
  name                    = "prtauth-cus-chi-01"
  express_route_port_name = azurerm_express_route_port.er-port-cus-chi-01.name
  resource_group_name     = azurerm_resource_group.Ent_vWAN_RG
}

# Then create the circuits
resource "azurerm_express_route_circuit" "er-cmi-chi-cus-01" {
    name                = "er-cmi-chi-cus-01"
    location            = "chicago"
    resource_group_name = azurerm_resource_group.Ent_ExpressRoutes_RG.name
    bandwidth_in_gbps   = 10
    express_route_port_id = azurerm_express_route_port.er-port-cus-chi-01.id
    sku {
        tier = "Standard"
        family = "UnlimitedData"
    }
}

resource "azurerm_express_route_circuit" "er-cmi-dal-eus-01" {
    name                = "er-cmi-dal-eus-01"
    location            = "dallas"
    resource_group_name = azurerm_resource_group.Ent_ExpressRoutes_RG.name
    bandwidth_in_gbps   = 10
    express_route_port_id = azurerm_express_route_port.er-port-cus-dal-01.id
    sku {
        tier = "Standard"
        family = "MeteredData"
    }
}

resource "azurerm_express_route_circuit" "er-atl-atl-01" {
    name                = "er-atl-atl-01"
    location            = "atlanta"
    resource_group_name = azurerm_resource_group.Ent_ExpressRoutes_RG.name
    bandwidth_in_gbps   = 10
    express_route_port_id = azurerm_express_route_port.er-port-eus-atl-01.id
    sku {
        tier = "Standard"
        family = "UnlimitedData"
    }
}

resource "azurerm_express_route_circuit" "er-atl-mia-01" {
    name                = "er-atl-mia-01"
    location            = "miami"
    resource_group_name = azurerm_resource_group.Ent_ExpressRoutes_RG.name
    bandwidth_in_gbps   = 10
    express_route_port_id = azurerm_express_route_port.er-port-eus-mia-01.id
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

# Create the connection objects to link the Express Route Circuits to the Virtual WAN
resource "azurerm_express_route_connection" "con-er-cmi-chi-cus-01" {
  name                             = "con-er-cmi-chi-cus-01"
  express_route_gateway_id         = azurerm_express_route_gateway.ergw-vwan-cus-01.id
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.er-cmi-chi-cus-01-prvpeer.id
}

resource "azurerm_express_route_connection" "con-er-cmi-dal-eus-01" {
  name                             = "con-er-cmi-dal-eus-01"
  express_route_gateway_id         = azurerm_express_route_gateway.ergw-vwan-eus-01.id
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.er-cmi-dal-eus-01-prvpeer.id
}

resource "azurerm_express_route_connection" "con-er-atl-atl-01" {
  name                             = "con-er-atl-atl-01"
  express_route_gateway_id         = azurerm_express_route_gateway.ergw-vwan-cus-01.id
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.er-atl-atl-01-prvpeer.id
}

resource "azurerm_express_route_connection" "con-er-atl-mia-01" {
  name                             = "con-er-atl-mia-01"
  express_route_gateway_id         = azurerm_express_route_gateway.ergw-vwan-eus-01.id
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.er-atl-mia-01-prvpeer.id
}
#endregion

