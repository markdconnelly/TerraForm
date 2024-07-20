provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "example" {
    name     = "example-resource-group"
    location = "West US"
}

resource "azurerm_user_assigned_identity" "example" {
    name                = "example-identity"
    resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_storage_account" "example" {
    name                     = "example-storage-account"
    resource_group_name      = azurerm_resource_group.example.name
    location                 = azurerm_resource_group.example.location
    account_tier             = "Standard"
    account_replication_type = "ZRS"
    identity {
        type                     = "UserAssigned"
        identity_ids             = [azurerm_user_assigned_identity.example.id]
    }
}

resource "azurerm_private_dns_zone" "example" {
    name                = "example.private.link"
    resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
    name                  = "example-link"
    resource_group_name   = azurerm_resource_group.example.name
    private_dns_zone_name = azurerm_private_dns_zone.example.name
    virtual_network_id    = "/subscriptions/<subscription_id>/resourceGroups/<resource_group_name>/providers/Microsoft.Network/virtualNetworks/<virtual_network_name>"
}

resource "azurerm_private_endpoint" "example" {
    name                          = "example-endpoint"
    resource_group_name           = azurerm_resource_group.example.name
    location                      = azurerm_resource_group.example.location
    subnet_id                     = "/subscriptions/<subscription_id>/resourceGroups/<resource_group_name>/providers/Microsoft.Network/virtualNetworks/<virtual_network_name>/subnets/<subnet_name>"
    private_dns_zone_group_name   = "example-group"
    private_dns_zone_name         = azurerm_private_dns_zone.example.name
    private_service_connection {
        name                           = "example-connection"
        private_connection_resource_id = azurerm_storage_account.example.id
        subresource_names              = ["blob"]
    }
}