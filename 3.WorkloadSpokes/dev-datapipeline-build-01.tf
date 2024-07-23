#region Building Blocks
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Ent_DevOps_DataPipeline-01_RG" {
  name     = "Ent_DevOps_DataPipeline-01_RG"
  location = "Central US"
          tags = {
        environment = "production"
        costcenter = "DevOps"
        description = "Resource group for general data pipeline services in the DevOps environment. Critical business operations are dependent on these pipelines."
    }
}

# Create a user assigned managed identity to perform operations on behalf of the Data Pipeline
resource "azurerm_user_assigned_identity" "mgid-devops-datapipeline-01" {
  name                = "mgid-devops-datapipeline-01"
  location            = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}

# Key Vault for the workload
# Create an Azure Key Vault to store the certificate for deep packet inspection
resource "azurerm_key_vault" "kv-devops-datapipeline-01" {
  name                        = "kv-ent-vwan"
  location                    = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.location
  resource_group_name         = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
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

resource "azurerm_key_vault_key" "key-adf-devops-dp-01-rotate1yr" {
  name         = "key-adf-devops-dp-01-rotate1yr"
  key_vault_id = azurerm_key_vault.kv-it-infrastructure-encryption.id
  key_type     = "RSA"
  key_size     = 4096
  # fix activation and expiration dates here
  not_before_date = "2021-01-01T00:00:00+00:00"
  expiration_date = "2022-01-01T00:00:00+00:00"
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  # fix rotation policy logic here
  rotation_policy {
    automatic {
      time_before_expiry = "P3M"
    }

    expire_after         = "P1Y"
    notify_before_expiry = "P30D"
  }
}

resource "azurerm_key_vault_key" "key-stgdevopsdp01-rotate1yr" {
  name         = "key-stgdevopsdp01-rotate1yr"
  key_vault_id = azurerm_key_vault.kv-it-infrastructure-encryption.id
  key_type     = "RSA"
  key_size     = 4096
  # fix activation and expiration dates here
  not_before_date = "2021-01-01T00:00:00+00:00"
  expiration_date = "2022-01-01T00:00:00+00:00"
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  # fix rotation policy logic here
  rotation_policy {
    automatic {
      time_before_expiry = "P3M"
    }

    expire_after         = "P1Y"
    notify_before_expiry = "P30D"
  }
}

# probably too granular of a scope, but illustrates
resource "azurerm_role_assignment" "roleassign-key-adf-devops-dp-01-rotate1yr" {
  scope                = azurerm_key_vault_key.key-adf-devops-dp-01-rotate1yr.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.mgid-ent-kv-infrastructure-encryption.principal_id
}
#endregion

#region CUS Network Block
resource "azurerm_virtual_network" "vnet-cus-datapipeline-01" {
  name                = "vnet-cus-datapipeline-01"
  address_space       = ["172.16.100.0/24"]
  dns_servers = [ "172.16.0.6","172.16.0.7","172.17.0.6" ]
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}


resource "azurerm_subnet" "subnet-cus-datapipeline-01-default" {
  name                 = "subnet-cus-datapipeline-01-default"
  resource_group_name  = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
  virtual_network_name = azurerm_virtual_network.vnet-cus-datapipeline-01.name
  address_prefixes     = ["172.16.100.0/24"]
}

resource "azurerm_network_security_group" "nsg-cus-datapipeline-01" {
  name                = "nsg-cus-datapipeline-01"
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}
#endregion

#region EUS 2 Network Block
resource "azurerm_virtual_network" "vnet-eus-datapipeline-01" {
  name                = "vnet-eus-datapipeline-01"
  address_space       = ["172.17.100.0/24"]
  dns_servers = [ "172.17.0.6","172.17.0.7","172.16.0.6" ]
  location            = azurerm_virtual_wan_hub.vHub-EUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}


resource "azurerm_subnet" "subnet-eus-datapipeline-01-default" {
  name                 = "subnet-eus-datapipeline-01-default"
  resource_group_name  = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
  virtual_network_name = azurerm_virtual_network.vnet-eus-datapipeline-01.name
  address_prefixes     = ["172.17.100.0/24"]
}

resource "azurerm_network_security_group" "nsg-eus-datapipeline-01" {
  name                = "nsg-eus-datapipeline-01"
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
}

#endregion

#region Data Factory
# Data Factory for the workload
resource "azurerm_data_factory" "adf-devops-dp-01" {
  name                = "adf-devops-dp-01"
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
  public_network_enabled = false
  customer_managed_key_id = key-adf-devops-dp-01-rotate1yr.id
  customer_managed_key_identity_id = azurerm_user_assigned_identity.mgid-ent-kv-infrastructure-encryption.id
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mgid-devops-datapipeline-01.id]
  }
  github_configuration {
    account_name = "github"
    branch_name = "main"
    git_url = "https://github.com"
    repository_name = "myrepo"
    root_folder = "/"
  }
}
#endregion

#region Storage Account
resource "azurerm_storage_account" "stgdevopsdp01" {
  name                     = "stgdevopsdp01"
  resource_group_name      = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
  location                 = azurerm_virtual_wan_hub.vHub-CUS-01.location
  default_to_oauth_authentication = true
  account_kind = "StorageV2"
  account_tier             = "Premium"
  account_replication_type = "RAGZRS"
  access_tier = "Hot"
  enable_https_traffic_only = true
  min_tls_version = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled = false
  infrastructure_encryption_enabled = true
  allowed_copy_scope = "PrivateLink"
  dns_endpoint_type = "AzureDnsZone"
    blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true
  }
  routing {
    choice = "MicrosoftRouting"
    publish_internet_endpoints = false
    publish_microsoft_endpoints = true
  }
  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["10.0.0.0/8"]
    bypass = "AzureServices"
    virtual_network_subnet_ids = [subnet-cus-datapipeline-01-default.id, subnet-eus-datapipeline-01-default.id]
  }
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mgid-ent-kv-infrastructure-encryption.id]
  }
  customer_managed_key {
    key_vault_key_id = azurerm_key_vault_key.key-stgdevopsdp01-rotate1yr.id
    user_assigned_identity_id = azurerm_user_assigned_identity.mgid-ent-kv-infrastructure-encryption.id
  
  }
}
#endregion

#region Containers
resource "azurerm_storage_container" "stage1-container" {
  name                  = "stage1-container"
  storage_account_name  = azurerm_storage_account.stgdevopsdp01.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "stage2-container" {
  name                  = "stage2-container"
  storage_account_name  = azurerm_storage_account.stgdevopsdp01.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "stage3-container" {
  name                  = "stage3-container"
  storage_account_name  = azurerm_storage_account.stgdevopsdp01.name
  container_access_type = "private"
}
#endregion

#region Queues
resource "azurerm_storage_queue" "stage1-queue" {
  name                 = "stage1-queue"
  storage_account_name = azurerm_storage_account.stgdevopsdp01.name
}

resource "azurerm_storage_queue" "stage2-queue" {
  name                 = "stage2-queue"
  storage_account_name = azurerm_storage_account.stgdevopsdp01.name
}

resource "azurerm_storage_queue" "stage3-queue" {
  name                 = "stage3-queue"
  storage_account_name = azurerm_storage_account.stgdevopsdp01.name
}
#endregion

#region App Service Plan
resource "azurerm_service_plan" "srvpln-cus-devops-dp-01" {
  name                = "srvpln-devops-dp-01"
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  os_type             = "Windows"
  sku_name            = "P0v3"
  worker_count = 2
  zone_balancing_enabled = true
}
#endregion

#region Function Apps
resource "azurerm_windows_function_app" "fnc-data-process-01" {
  name                = "fnc-data-process-01"
  resource_group_name = azurerm_resource_group.Ent_DevOps_DataPipeline-01_RG.name
  location            = azurerm_virtual_wan_hub.vHub-CUS-01.location
  service_plan_id = azurerm_service_plan.srvpln-cus-devops-dp-01.id
  client_certificate_enabled = true
  client_certificate_mode = "Required"
  enabled = true
  https_only = true
  public_network_access_enabled = false
  key_vault_reference_identity_id = [azurerm_user_assigned_identity.mgid-devops-datapipeline-01.id]
  virtual_network_subnet_id = subnet-cus-datapipeline-01-default.id
  auth_settings {
    enabled = true
    default_provider = "AzureActiveDirectory"
    issuer = "https://sts.windows.net/72f988bf-86f1-41af-91ab-2d7cd011db47/"
    runtime_version = "~3"
  }
  site_config {
    app_service_logs {

    }
    application_stack {
      dotnet_version = v8.0
      use_dotnet_isolated_runtime = true
    }
    app_scale_limit = 5
    application_insights_connection_string = ""
    application_insights_key = ""
  }
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mgid-devops-datapipeline-01.id]
  
  }
}

#endregion

#region Logic App

#endregion






