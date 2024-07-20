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

# Create a user assigned managed identity to perform operations on behalf of the vWAN
resource "azurerm_user_assigned_identity" "mgid-ent-vwan" {
  name                = "mgid-ent-vwan"
  location            = azurerm_resource_group.Ent_vWAN_RG.location
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
}

# Create an Azure Key Vault to sore the certificate for deep packet inspection
resource "azurerm_key_vault" "example" {
  name                        = "kv-ent-vwan"
  location                    = azurerm_resource_group.Ent_vWAN_RG.location
  resource_group_name         = azurerm_resource_group.Ent_vWAN_RG.name
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

# import the current certificate frome the Key Vault
# This is an error prone area. Figure out what cert config works consistently and update this block
resource "azurerm_key_vault_certificate" "vWAN-DPI-Certificate" {
  name         = "vWAN-DPI-Certificate"
  key_vault_id = azurerm_key_vault.kv-ent-vwan.id
  certificate {
    contents = "Base64CertContents"
    password = "SecretHere"
  }
  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["internal.contoso.com", "domain.hello.world"]
      }

      subject            = "CN=hello-world"
      validity_in_months = 12
    }
  }
}

#endregion

#region VirtualWAN
# Create the Virtual WAN
resource "azurerm_virtual_wan" "vWAN-Enterprise-Services" {
    name                = "vWAN-Enterprise-Services"
    location            = "Central US"
    resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
    allow_branch_to_branch_traffic = true
    office365_local_breakout_category = OptimizeAndAllow
    type = Standard
}

# Create the Virtual WAN Hubs
resource "azurerm_virtual_wan_hub" "vHub-CUS-01" {
    name                = "vHub-CUS-01"
    resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
    location = centralus
    virtual_wan_id = azurerm_virtual_wan.vWAN-Enterprise-Services.id
    address_prefix = "172.16.0.0/24"
    hub_routing_preference = ASPath
}

resource "azurerm_virtual_wan_hub" "vHub-EUS-01" {
    name                = "vHub-EUS-01"
    resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
    location = eastus2
    virtual_wan_id = azurerm_virtual_wan.vWAN-Enterprise-Services.id
    address_prefix = "172.17.0.0/24"
}

# Create the firewall policy for the Virtual WAN
# Because manual management of firewall policies is common, it might be best to just import 
# this object and let it be managed in the gui. 
resource "azurerm_firewall_policy" "azfw-policy-vwan" {
  name                = "azfw-policy-vwan"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG
  location            = azurerm_resource_group.Ent_vWAN_RG
  sku = Premium
  auto_learn_private_ranges_enabled = true
  threat_intelligence_mode = Deny
  dns {
    proxy_enabled = true
    servers = [ "172.16.1.6","172.16.1.7","172.17.1.6","172.17.1.7" ] #Active Directory DNS
  }
  identity {
    type = UserAssigned
    identity_ids = azurerm_user_assigned_identity.mgid-ent-vwan.id
  }
  insights {
    enabled = true
    default_log_analytics_workspace_id = "Manually Link Logs Here"
    retention_in_days = 7
  }
  intrusion_detection {
    mode = Deny
  }
  tls_certificate {
    name = azurerm_key_vault_certificate.vWAN-DPI-Certificate.name
    key_vault_secret_id = azurerm_key_vault.kv-ent-vwan.id

  }
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

#region 1. er-cmi-chi-cus-01
resource "azurerm_express_route_port" "er-port-cmi-chi-cus-01" {
  name                = "er-port-cmi-chi-cus-01"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  location            = azurerm_virtual_hub.vHub-CUS-01.location
  peering_location    = "MegaPort"
  bandwidth_in_gbps   = 10
  billing_type = UnlimitedData
  encapsulation       = "Dot1Q"
}

resource "azurerm_express_route_port_authorization" "prtauth-cmi-chi-cus-01" {
  name                    = "prtauth-cmi-chi-cus-01"
  express_route_port_name = azurerm_express_route_port.er-port-cmi-chi-cus-01.name
  resource_group_name     = azurerm_resource_group.Ent_vWAN_RG
}

resource "azurerm_express_route_circuit" "er-cmi-chi-cus-01" {
    name                = "er-cmi-chi-cus-01"
    location            = azurerm_virtual_hub.vHub-CUS-01.location
    resource_group_name = azurerm_resource_group.Ent_ExpressRoutes_RG.name
    service_provider_name = "MegaPort"
    peering_location = "Chicago"
    bandwidth_in_gbps   = 10
    express_route_port_id = azurerm_express_route_port.er-port-cmi-chi-cus-01.id
    sku {
        tier = "Standard"
        family = "UnlimitedData"
    }
}

resource "azurerm_express_route_circuit_peering" "er-cmi-chi-cus-01-prvpeer" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.er-cmi-chi-cus-01.name
  resource_group_name           = azurerm_resource_group.Ent_ExpressRoutes_RG.name
  shared_key                    = "ItsASecret"
  peer_asn                      = 65656
  ipv4_enabled = true
  primary_peer_address_prefix   = "192.168.1.0/30"
  secondary_peer_address_prefix = "192.168.2.0/30"
  vlan_id                       = 87
}

resource "azurerm_express_route_connection" "con-er-cmi-chi-cus-01" {
  name                             = "con-er-cmi-chi-cus-01"
  express_route_gateway_id         = azurerm_express_route_gateway.ergw-vwan-cus-01.id
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.er-cmi-chi-cus-01-prvpeer.id
}
#endregion

#region 2. er-cmi-dal-eus-01
resource "azurerm_express_route_port" "er-port-cmi-dal-eus-01" {
  name                = "er-port-cmi-dal-eus-01"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  location            = azurerm_virtual_hub.vHub-EUS-01.location
  peering_location    = "AT&T"
  bandwidth_in_gbps   = 10
  billing_type = MeteredData
  encapsulation       = "Dot1Q"
}

resource "azurerm_express_route_port_authorization" "prtauth-cmi-dal-eus-01" {
  name                    = "prtauth-cmi-dal-eus-01"
  express_route_port_name = azurerm_express_route_port.er-port-cmi-dal-eus-01.name
  resource_group_name     = azurerm_resource_group.Ent_vWAN_RG.name
}

resource "azurerm_express_route_circuit" "er-cmi-dal-eus-01" {
    name                = "er-cmi-dal-eus-01"
    location            = azurerm_virtual_hub.vHub-EUS-01.location
    resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
    service_provider_name = "AT&T"
    peering_location = "Dallas"
    bandwidth_in_gbps   = 10
    express_route_port_id = azurerm_express_route_port.er-port-cus-dal-01.id
    sku {
        tier = "Standard"
        family = "MeteredData"
    }
}

resource "azurerm_express_route_circuit_peering" "er-cmi-dal-eus-01-prvpeer" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.er-cmi-dal-eus-01.name
  resource_group_name           = azurerm_resource_group.Ent_vWAN_RG.name
  shared_key                    = "ItsASecret"
  peer_asn                      = 65656
  ipv4_enabled = true
  primary_peer_address_prefix   = "192.168.3.0/30"
  secondary_peer_address_prefix = "192.168.4.0/30"
  vlan_id                       = 92
}

resource "azurerm_express_route_connection" "con-er-cmi-dal-eus-01" {
  name                             = "con-er-cmi-dal-eus-01"
  express_route_gateway_id         = azurerm_express_route_gateway.ergw-vwan-eus-01.id
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.er-cmi-dal-eus-01-prvpeer.id
}
#endregion

#region 3. er-atl-atl-cus-01
resource "azurerm_express_route_port" "er-port-atl-atl-cus-01" {
  name                = "er-port-atl-atl-cus-01"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  location            = azurerm_virtual_hub.vHub-CUS-01.location
  peering_location    = "MegaPort"
  bandwidth_in_gbps   = 10
  billing_type = UnlimitedData
  encapsulation       = "Dot1Q"
}

resource "azurerm_express_route_port_authorization" "prtauth-atl-atl-cus-01" {
  name                    = "prtauth-atl-atl-cus-01"
  express_route_port_name = azurerm_express_route_port.er-port-atl-atl-cus-01.name
  resource_group_name     = azurerm_resource_group.Ent_vWAN_RG.name
}

resource "azurerm_express_route_circuit" "er-atl-atl-cus-01" {
    name                = "er-atl-atl-cus-01"
    location            = azurerm_virtual_hub.vHub-CUS-01.location
    resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
    service_provider_name = "MegaPort"
    peering_location = "Atlanta"
    bandwidth_in_gbps   = 10
    express_route_port_id = azurerm_express_route_port.er-port-atl-atl-cus-01.id
    sku {
        tier = "Standard"
        family = "UnlimitedData"
    }
}

resource "azurerm_express_route_circuit_peering" "er-atl-atl-cus-01-prvpeer" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.er-atl-atl-cus-01.name
  resource_group_name           = azurerm_resource_group.Ent_vWAN_RG.name
  shared_key                    = "ItsASecret"
  peer_asn                      = 65656
  ipv4_enabled = true
  primary_peer_address_prefix   = "192.168.5.0/30"
  secondary_peer_address_prefix = "192.168.6.0/30"
  vlan_id                       = 35
}

resource "azurerm_express_route_connection" "con-er-atl-atl-cus-01" {
  name                             = "con-er-atl-atl-cus-01"
  express_route_gateway_id         = azurerm_express_route_gateway.ergw-vwan-cus-01.id
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.er-atl-atl-cus-01-prvpeer.id
}
#endregion

#region 4. er-atl-mia-eus-01
resource "azurerm_express_route_port" "er-port-atl-mia-eus-01" {
  name                = "er-port-atl-mia-eus-01"
  resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
  location            = azurerm_virtual_hub.vHub-EUS-01.location
  peering_location    = "AT&T"
  bandwidth_in_gbps   = 10
  billing_type = MeteredData
  encapsulation       = "Dot1Q"
}

resource "azurerm_express_route_port_authorization" "prtauth-cmi-chi-cus-01" {
  name                    = "prtauth-cmi-chi-cus-01"
  express_route_port_name = azurerm_express_route_port.er-port-atl-mia-eus-01.name
  resource_group_name     = azurerm_resource_group.Ent_vWAN_RG.name
}

resource "azurerm_express_route_circuit" "er-atl-mia-01" {
    name                = "er-atl-mia-eus-01"
    location            = azurerm_virtual_hub.vHub-EUS-01.location
    resource_group_name = azurerm_resource_group.Ent_vWAN_RG.name
    service_provider_name = "AT&T"
    peering_location = "Miami"
    bandwidth_in_gbps   = 10
    express_route_port_id = azurerm_express_route_port.er-port-atl-mia-eus-01.id
    sku {
        tier = "Standard"
        family = "MeteredData"
    }
}

resource "azurerm_express_route_circuit_peering" "er-atl-mia-01-prvpeer" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.er-atl-mia-01.name
  resource_group_name           = azurerm_resource_group.Ent_vWAN_RG.name
  shared_key                    = "ItsASecret"
  peer_asn                      = 65656
  ipv4_enabled = true
  primary_peer_address_prefix   = "192.168.7.0/30"
  secondary_peer_address_prefix = "192.168.8.0/30"
  vlan_id                       = 17
}

resource "azurerm_express_route_connection" "con-er-atl-mia-eus-01" {
  name                             = "con-er-atl-mia-eus-01"
  express_route_gateway_id         = azurerm_express_route_gateway.ergw-vwan-eus-01.id
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.er-atl-mia-01-prvpeer.id
}#endregion
#endregion
#endregion