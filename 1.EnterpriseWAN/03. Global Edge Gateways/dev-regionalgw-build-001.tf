data "azurerm_api_management" "example" {
  name                = "example-api"
  resource_group_name = "example-resources"
}

data "azurerm_api_management_api" "example" {
  name                = "search-api"
  api_management_name = data.azurerm_api_management.example.name
  resource_group_name = data.azurerm_api_management.example.resource_group_name
  revision            = "2"
}

data "azurerm_api_management_gateway" "example" {
  name              = "example-gateway"
  api_management_id = data.azurerm_api_management.example.id
}

resource "azurerm_api_management_gateway_api" "example" {
  gateway_id = data.azurerm_api_management_gateway.example.id
  api_id     = data.azurerm_api_management_api.example.id
}