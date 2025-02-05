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
resource "azurerm_resource_group" "Ent_SecOps_KeyVault_RG" {
    name     = "Ent_SecOps_KeyVault_RG"
    location = "Central US"
        tags = {
        environment = "production"
        costcenter = "SecOps"
        description = "Resource group for Security Operations key vault services"
    }
}

# Create the resource groups required for the Entreprise Log Analytics services
resource "azurerm_resource_group" "Ent_IT_KeyVault_RG" {
    name     = "Ent_IT_KeyVault_RG"
    location = "Central US"
        tags = {
        environment = "production"
        costcenter = "IT"
        description = "Resource group for IT key vault services"
    }
}

# Create a user assigned managed identity to perform operations on behalf of the Certificate Operations Key Vault
resource "azurerm_user_assigned_identity" "mgid-ent-kv-certops" {
  name                = "mgid-ent-kv-certops"
  location            = azurerm_resource_group.Ent_SecOps_KeyVault_RG.location
  resource_group_name = azurerm_resource_group.Ent_SecOps_KeyVault_RG.name
}

# Create a user assigned managed identity to perform operations on behalf of the Infrastructure Encryption Key Vault
resource "azurerm_user_assigned_identity" "mgid-ent-kv-infrastructure-encryption" {
  name                = "mgid-ent-kv-infrastructure-encryption"
  location            = azurerm_resource_group.Ent_IT_KeyVault_RG.location
  resource_group_name = azurerm_resource_group.Ent_IT_KeyVault_RG.name
}

# Create a user assigned managed identity to perform operations on behalf of the Backup Key Vault
resource "azurerm_user_assigned_identity" "mgid-ent-kv-backup" {
  name                = "mgid-ent-kv-backup"
  location            = azurerm_resource_group.Ent_IT_KeyVault_RG.location
  resource_group_name = azurerm_resource_group.Ent_IT_KeyVault_RG.name
}
#endregion

#region KeyVault Build
# Create an Azure Key Vault for certificate services for the Security Operations team
resource "azurerm_key_vault" "kv-secops-certservices" {
  name                        = "kv-secops-certservices"
  location                    = azurerm_resource_group.Ent_SecOps_KeyVault_RG.location
  resource_group_name         = azurerm_resource_group.Ent_SecOps_KeyVault_RG.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name = "standard" 
  enable_rbac_authorization = true
  public_network_access_enabled = false
  network_acls {
    default_action = Deny
    bypass = AzureServices
  }
}

# Create a diagnostic setting for the certificate services key vault
resource "azurerm_monitor_diagnostic_setting" "kv-secops-certservices-sentinel-diag" {
  name               = "kv-secops-certservices-sentinel-diag"
  target_resource_id = azurerm_key_vault.kv-secops-certservices.id
  log_analytics_workspace_id = law-sentinel-cus-01.id
  log_analytics_destination_type = AzureDiagnostics

  enabled_log {
    category = "AllEvents"
  }
  metric {
    category = "AllMetrics"
    }
}

# Create an Azure Key Vault for Infrastructure encyption services
resource "azurerm_key_vault" "kv-it-infrastructure-encryption" {
  name                        = "kv-it-infrastructure-encryption"
  location                    = azurerm_resource_group.Ent_IT_KeyVault_RG.location
  resource_group_name         = azurerm_resource_group.Ent_IT_KeyVault_RG.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name = "standard" 
  enable_rbac_authorization = true
  public_network_access_enabled = false
  network_acls {
    default_action = Deny
    bypass = AzureServices
  }
}

# Create a diagnostic setting for the infrastructure encryption key vault
resource "azurerm_monitor_diagnostic_setting" "kv-it-infrastructure-encryption-sentinel-diag" {
  name               = "kv-it-infrastructure-encryption-sentinel-diag"
  target_resource_id = azurerm_key_vault.kv-it-infrastructure-encryption.id
  log_analytics_workspace_id = law-sentinel-cus-01.id
  log_analytics_destination_type = AzureDiagnostics

  enabled_log {
    category = "AllEvents"
  }
  metric {
    category = "AllMetrics"
    }
}

# Create an Azure Key Vault for backup services
resource "azurerm_key_vault" "kv-it-backup-services" {
  name                        = "kv-it-backup-services"
  location                    = azurerm_resource_group.Ent_IT_KeyVault_RG.location
  resource_group_name         = azurerm_resource_group.Ent_IT_KeyVault_RG.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name = "standard" 
  enable_rbac_authorization = true
  public_network_access_enabled = false
  network_acls {
    default_action = Deny
    bypass = AzureServices
  }
}

# Create a diagnostic setting for the backup key vault
resource "azurerm_monitor_diagnostic_setting" "kv-it-backup-services-sentinel-diag" {
  name               = "kv-it-backup-services-sentinel-diag"
  target_resource_id = azurerm_key_vault.kv-it-backup-services.id
  log_analytics_workspace_id = law-sentinel-cus-01.id
  log_analytics_destination_type = AzureDiagnostics

  enabled_log {
    category = "AllEvents"
  }
  metric {
    category = "AllMetrics"
    }
}
#endregion

#region Keys/DESs
resource "azurerm_key_vault_key" "key-des-vm-cus-01" {
  name         = "key-des-vm-cus-01"
  key_vault_id = azurerm_key_vault.kv-it-infrastructure-encryption.id
  key_type     = "RSA"
  key_size     = 4096

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_key_vault_key" "key-des-vm-eus-01" {
  name         = "key-des-vm-eus-01"
  key_vault_id = azurerm_key_vault.kv-it-infrastructure-encryption.id
  key_type     = "RSA"
  key_size     = 4096

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_disk_encryption_set" "des-vm-cus-01" {
  name                = "des-vm-cus-01"
  resource_group_name = azurerm_resource_group.Ent_IT_KeyVault_RG.name
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  key_vault_key_id    = azurerm_key_vault_key.key-des-vm-cus-01.id
  auto_key_rotation_enabled = true
  encryption_type = EncryptionAtRestWithPlatformAndCustomerKeys
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.mgid-ent-kv-infrastructure-encryption.id,
    ]
  }
}

resource "azurerm_disk_encryption_set" "des-vm-eus-01" {
  name                = "des-vm-eus-01"
  resource_group_name = azurerm_resource_group.Ent_IT_KeyVault_RG.name
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  key_vault_key_id    = azurerm_key_vault_key.key-des-vm-eus-01.id
  auto_key_rotation_enabled = true
  encryption_type = EncryptionAtRestWithPlatformAndCustomerKeys
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.mgid-ent-kv-infrastructure-encryption.id,
    ]
  }
}
