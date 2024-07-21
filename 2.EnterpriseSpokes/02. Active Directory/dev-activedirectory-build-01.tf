#region BuldingBlocks
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Ent_SecOps_ActiveDirectory_RG" {
  name     = "Ent_SecOps_ActiveDirectory_RG"
  location = "Central US"
}
#endregion

#region Central US Network
resource "azurerm_virtual_network" "vnet-cus-activedirectory" {
  name                = "vnet-cus-activedirectory"
  address_space       = ["172.16.1.0/24"]
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
}


resource "azurerm_subnet" "subnet-cus-activedirectory" {
  name                 = "subnet-cus-activedirectory"
  resource_group_name  = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
  virtual_network_name = azurerm_virtual_network.vnet-cus-activedirectory.name
  address_prefixes     = ["172.16.1.0/24"]
}

resource "azurerm_network_interface" "nic-cus-ad-01" {
  name                = "nic-cus-ad-01"
  location            = azurerm_resource_group.azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name

  ip_configuration {
    name                          = "nic-cus-ad-01-ip"
    subnet_id                     = azurerm_subnet.subnet-cus-activedirectory.id    
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.16.0.6"
  }
}

resource "azurerm_network_interface" "nic-cus-ad-02" {
  name                = "nic-cus-ad-02"
  location            = azurerm_resource_group.azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name

  ip_configuration {
    name                          = "nic-cus-ad-02-ip"
    subnet_id                     = azurerm_subnet.subnet-cus-activedirectory.id    
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.16.0.7"
  }
}
#endregion

#region East US 2 Network

resource "azurerm_virtual_network" "vnet-eus-activedirectory" {
  name                = "vnet-eus-activedirectory"
  address_space       = ["172.17.1.0/24"]
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
}


resource "azurerm_subnet" "subnet-eus-activedirectory" {
  name                 = "subnet-eus-activedirectory"
  resource_group_name  = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
  virtual_network_name = azurerm_virtual_network.vnet-eus-activedirectory.name
  address_prefixes     = ["172.17.1.0/24"]
}

resource "azurerm_network_interface" "nic-eus-ad-01" {
  name                = "nic-eus-ad-01"
  location            = azurerm_resource_group.azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name

  ip_configuration {
    name                          = "nic-eus-ad-01-ip"
    subnet_id                     = azurerm_subnet.subnet-eus-activedirectory.id    
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.17.0.6"
  }
}

resource "azurerm_network_interface" "nic-eus-ad-02" {
  name                = "nic-eus-ad-02"
  location            = azurerm_resource_group.azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name

  ip_configuration {
    name                          = "nic-eus-ad-02-ip"
    subnet_id                     = azurerm_subnet.subnet-eus-activedirectory.id    
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.17.0.7"
  }
}
#endregion

#region Active Directory
resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
#endregion