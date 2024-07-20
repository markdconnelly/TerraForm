## Prompt: Can you write me the terraform block to deploy an express route circuit and include all configurations?

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

resource "azurerm_resource_group" "example" {
    name     = "example-resource-group"
    location = "West US"
}

resource "azurerm_virtual_network" "example" {
    name                = "example-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
    name                 = "example-subnet"
    resource_group_name  = azurerm_resource_group.example.name
    virtual_network_name = azurerm_virtual_network.example.name
    address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_express_route_circuit" "example" {
    name                = "example-expressroute"
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    sku                 = "Standard_MeteredData"
    service_provider_name = "Equinix"
    peering_location = "Seattle"
    bandwidth_in_mbps = 100

    tags = {
        environment = "production"
    }
}

resource "azurerm_express_route_circuit_authorization" "example" {
    name                = "example-authorization"
    resource_group_name = azurerm_resource_group.example.name
    circuit_name        = azurerm_express_route_circuit.example.name
    authorization_key   = "my-authorization-key"
}

resource "azurerm_express_route_circuit_peering" "example" {
    name                = "example-peering"
    resource_group_name = azurerm_resource_group.example.name
    circuit_name        = azurerm_express_route_circuit.example.name
    peering_type        = "AzurePrivatePeering"
    peer_asn            = 65000
    primary_peer_address_prefix = "192.168.0.0/30"
    secondary_peer_address_prefix = "192.168.0.4/30"
    vlan_id             = 100
}

# Prompt 1 informs prompt 2
/* Prompt 2: Can you write me the terraform block to deploy 4 express routes and connect them to an express route gateways deployed in central and east us? 
The first express route should connect via chicago to central us, 
the second express route should connect via dallas to east us 2, 
the third express route should connect via atlanta to central us, 
and the fourth express route should connect via miami to east us 2.
Include all available configurations */
