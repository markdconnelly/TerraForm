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

resource "azurerm_virtual_wan" "example" {
    name                = "my-virtual-wan"
    location            = "West US"
    resource_group_name = azurerm_resource_group.example.name

    tags = {
        environment = "production"
    }
}

resource "azurerm_resource_group" "example" {
    name     = "my-resource-group"
    location = "West US"
}

resource "azurerm_virtual_wan_hub" "example" {
    name                = "my-virtual-wan-hub"
    virtual_wan_name    = azurerm_virtual_wan.example.name
    resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_virtual_wan_hub_route_table" "example" {
    name                = "my-virtual-wan-hub-route-table"
    virtual_wan_hub_id  = azurerm_virtual_wan_hub.example.id
    resource_group_name = azurerm_resource_group.example.name

    route {
        name               = "route1"
        address_prefix     = "10.0.0.0/16"
        next_hop_type      = "VirtualNetworkGateway"
        next_hop_in_ip_tag = "my-virtual-network-gateway"
    }
}

resource "azurerm_virtual_wan_hub_security_partner_provider" "example" {
    name                = "my-virtual-wan-hub-security-partner-provider"
    virtual_wan_hub_id  = azurerm_virtual_wan_hub.example.id
    resource_group_name = azurerm_resource_group.example.name

    security_provider_name = "my-security-provider"
    security_provider_type = "ZScaler"
}