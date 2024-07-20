/*
Prompt 2: Can you write me the terraform block to deploy 4 express routes and connect them to an express route gateways deployed in central and east us? 
The first express route should connect via chicago to central us, 
the second express route should connect via dallas to east us 2, 
the third express route should connect via atlanta to central us, 
and the fourth express route should connect via miami to east us 2.
Include all available configurations

This is better but still needs some tuning. The express route gateways are not connected to the express route circuits in our example, they will be connected to the
gatways inside of the vWAN. We can manually update that later. 
*/

resource "azurerm_express_route_circuit" "express_route_1" {
    name                = "express_route_1"
    location            = "chicago"
    resource_group_name = "your_resource_group_name"
    sku                 = "Standard_MeteredData"
    bandwidth_in_mbps   = 100
}

resource "azurerm_express_route_circuit" "express_route_2" {
    name                = "express_route_2"
    location            = "dallas"
    resource_group_name = "your_resource_group_name"
    sku                 = "Standard_MeteredData"
    bandwidth_in_mbps   = 100
}

resource "azurerm_express_route_circuit" "express_route_3" {
    name                = "express_route_3"
    location            = "atlanta"
    resource_group_name = "your_resource_group_name"
    sku                 = "Standard_MeteredData"
    bandwidth_in_mbps   = 100
}

resource "azurerm_express_route_circuit" "express_route_4" {
    name                = "express_route_4"
    location            = "miami"
    resource_group_name = "your_resource_group_name"
    sku                 = "Standard_MeteredData"
    bandwidth_in_mbps   = 100
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