#region BuldingBlocks
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Ent_SecOps_ActiveDirectory_RG" {
  name     = "Ent_SecOps_ActiveDirectory_RG"
  location = "Central US"
          tags = {
        environment = "production"
        costcenter = "Security Operations"
        description = "Resource group for Enterprise Active Directory services"
    }
}
#endregion

#region Central US Network
resource "azurerm_virtual_network" "vnet-cus-activedirectory" {
  name                = "vnet-cus-activedirectory"
  address_space       = ["172.16.0.0/24"]
  dns_servers = [ "172.16.0.6","172.16.0.7","172.17.0.6" ]
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
}


resource "azurerm_subnet" "subnet-cus-activedirectory" {
  name                 = "subnet-cus-activedirectory"
  resource_group_name  = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
  virtual_network_name = azurerm_virtual_network.vnet-cus-activedirectory.name
  address_prefixes     = ["172.16.0.0/24"]
}

resource "azurerm_network_interface" "nic-cus-ad-01" {
  name                = "nic-cus-ad-01"
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
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
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name

  ip_configuration {
    name                          = "nic-cus-ad-02-ip"
    subnet_id                     = azurerm_subnet.subnet-cus-activedirectory.id    
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.16.0.7"
  }
}

resource "azurerm_network_security_group" "nsg-cus-activedirectory" {
  name                = "nsg-cus-activedirectory"
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
}
# Add flow logs down the line after the IT ops tools are established
#endregion

#region East US 2 Network

resource "azurerm_virtual_network" "vnet-eus-activedirectory" {
  name                = "vnet-eus-activedirectory"
  address_space       = ["172.17.0.0/24"]
  dns_servers = [ "172.17.0.6","172.17.0.7","172.16.0.6" ]
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
}


resource "azurerm_subnet" "subnet-eus-activedirectory" {
  name                 = "subnet-eus-activedirectory"
  resource_group_name  = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
  virtual_network_name = azurerm_virtual_network.vnet-eus-activedirectory.name
  address_prefixes     = ["172.17.0.0/24"]
}

resource "azurerm_network_interface" "nic-eus-ad-01" {
  name                = "nic-eus-ad-01"
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
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
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name

  ip_configuration {
    name                          = "nic-eus-ad-02-ip"
    subnet_id                     = azurerm_subnet.subnet-eus-activedirectory.id    
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.17.0.7"
  }
}

resource "azurerm_network_security_group" "nsg-eus-activedirectory" {
  name                = "nsg-eus-activedirectory"
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
}
# Add flow logs down the line after the IT ops tools are established
#endregion

#region Active Directory
resource "azurerm_windows_virtual_machine" "vm-cus-ad-01" {
  name                = "vm-cus-ad-01"
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  size                = "Standard_F2" #Update to more practical sku
  admin_username      = "MakeUniqueAdminName"
  admin_password      = "MakeUniqueSecret"
  allow_extension_operations = true
  provision_vm_agent = true 
  patch_mode = "Manual"
  patch_assessment_mode = "AutomaticByPlatform"
  computer_name = "cus-ad-01"
  enable_automatic_updates = false
  reboot_setting = "Never"
  encryption_at_host_enabled = true
  secure_boot_enabled = true
  vtpm_enabled = true
  zone = "1"
  network_interface_ids = [
    azurerm_network_interface.nic-cus-ad-01.id,
  ]
  os_disk {
    name = "disk-cus-ad-01-os"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_ZRS"
    disk_size_gb = 100
    disk_encryption_set_id = azurerm_disk_encryption_set.des-vm-cus-01.id
  }
  #add 250GB Data Disk Here 
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "vm-cus-ad-02" {
  name                = "vm-cus-ad-02"
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  size                = "Standard_F2" #Update to more practical sku
  admin_username      = "MakeUniqueAdminName"
  admin_password      = "MakeUniqueSecret"
  allow_extension_operations = true
  provision_vm_agent = true 
  patch_mode = "Manual"
  patch_assessment_mode = "AutomaticByPlatform"
  computer_name = "cus-ad-02"
  enable_automatic_updates = false
  reboot_setting = "Never"
  encryption_at_host_enabled = true
  secure_boot_enabled = true
  vtpm_enabled = true
  zone = "2"
  network_interface_ids = [
  azurerm_network_interface.nic-cus-ad-02.id,
  ]
  os_disk {
    name = "disk-cus-ad-02-os"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_ZRS"
    disk_size_gb = 100
    disk_encryption_set_id = azurerm_disk_encryption_set.des-vm-cus-01.id
  }
  #add 250GB Data Disk Here 
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "vm-eus-ad-01" {
  name                = "vm-eus-ad-01"
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  size                = "Standard_F2" #Update to more practical sku
  admin_username      = "MakeUniqueAdminName"
  admin_password      = "MakeUniqueSecret"
  allow_extension_operations = true
  provision_vm_agent = true 
  patch_mode = "Manual"
  patch_assessment_mode = "AutomaticByPlatform"
  computer_name = "eus-ad-01"
  enable_automatic_updates = false
  reboot_setting = "Never"
  encryption_at_host_enabled = true
  secure_boot_enabled = true
  vtpm_enabled = true
  zone = "1"
  network_interface_ids = [
    azurerm_network_interface.nic-eus-ad-01.id,
  ]
  os_disk {
    name = "disk-eus-ad-01-os"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_ZRS"
    disk_size_gb = 100
    disk_encryption_set_id = azurerm_disk_encryption_set.des-vm-eus-01.id
  }
  #add 250GB Data Disk Here 
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "vm-eus-ad-02" {
  name                = "vm-eus-ad-02"
  resource_group_name = azurerm_resource_group.Ent_SecOps_ActiveDirectory_RG.name
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  size                = "Standard_F2" #Update to more practical sku
  admin_username      = "MakeUniqueAdminName"
  admin_password      = "MakeUniqueSecret"
  allow_extension_operations = true
  provision_vm_agent = true 
  patch_mode = "Manual"
  patch_assessment_mode = "AutomaticByPlatform"
  computer_name = "eus-ad-02"
  enable_automatic_updates = false
  reboot_setting = "Never"
  encryption_at_host_enabled = true
  secure_boot_enabled = true
  vtpm_enabled = true
  zone = "2"
  network_interface_ids = [
    azurerm_network_interface.nic-eus-ad-02.id,
  ]
  os_disk {
    name = "disk-eus-ad-02-os"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_ZRS"
    disk_size_gb = 100
    disk_encryption_set_id = azurerm_disk_encryption_set.des-vm-eus-01.id
  }
  #add 250GB Data Disk Here 
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
#endregion