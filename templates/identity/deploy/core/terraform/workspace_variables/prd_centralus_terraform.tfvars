# DNS configuration for the identity virtual network.
# These defaults are intentionally empty to avoid invalid placeholder values
# rejected by variables.tf. Override per-environment as needed.
identity_vnet_dns_servers = []
adds_dns_forwarders      = []
vnet_address_space = ["172.26.4.0/23"]

vnet_subnets = {
  subn-activedirectory-1 = {
    name             = "subn-activedirectory-1"
    address_prefixes = ["172.26.4.0/26"]
    nsg_rule_names = [
      "NSRC_Platform_AzureLoadBalancer_to_Any",
      "NSRC_RFC1918Priv_10_0_0_0_8_to_Any",
      "NSRC_RFC1918Priv_172_16_0_0_12_to_Any",
      "NSRC_RFC1918Priv_192_168_0_0_16_to_Any",
      "NSRC_Any_to_Any",
      "NSRC_RFC1918Priv_10_0_0_0_8_to_Any_Outbound",
      "NSRC_RFC1918Priv_172_16_0_0_12_to_Any_Outbound",
      "NSRC_RFC1918Priv_192_168_0_0_16_to_Any_Outbound",
      "NSRC_Any_to_Any_Outbound"
    ]
    default_outbound_access_enabled = false
  },
  subn-certificateauth-1 = {
    name             = "subn-certificateauth-1"
    address_prefixes = ["172.26.4.64/26"]
    nsg_rule_names = [
      "NSRC_Platform_AzureLoadBalancer_to_Any",
      "NSRC_RFC1918Priv_10_0_0_0_8_to_Any",
      "NSRC_RFC1918Priv_172_16_0_0_12_to_Any",
      "NSRC_RFC1918Priv_192_168_0_0_16_to_Any",
      "NSRC_Any_to_Any",
      "NSRC_RFC1918Priv_10_0_0_0_8_to_Any_Outbound",
      "NSRC_RFC1918Priv_172_16_0_0_12_to_Any_Outbound",
      "NSRC_RFC1918Priv_192_168_0_0_16_to_Any_Outbound",
      "NSRC_Any_to_Any_Outbound"
    ]
    default_outbound_access_enabled = false
  },
  subn-entraconnect-1 = {
    name             = "subn-entraconnect-1"
    address_prefixes = ["172.26.4.128/26"]
    nsg_rule_names = [
      "NSRC_Platform_AzureLoadBalancer_to_Any",
      "NSRC_RFC1918Priv_10_0_0_0_8_to_Any",
      "NSRC_RFC1918Priv_172_16_0_0_12_to_Any",
      "NSRC_RFC1918Priv_192_168_0_0_16_to_Any",
      "NSRC_Any_to_Any",
      "NSRC_RFC1918Priv_10_0_0_0_8_to_Any_Outbound",
      "NSRC_RFC1918Priv_172_16_0_0_12_to_Any_Outbound",
      "NSRC_RFC1918Priv_192_168_0_0_16_to_Any_Outbound",
      "NSRC_Any_to_Any_Outbound"
    ]
    default_outbound_access_enabled = false
  },
  subn-privateendpoint-1 = {
    name             = "subn-privateendpoint-1"
    address_prefixes = ["172.26.4.192/26"]
    nsg_rule_names = [
      "NSRC_Platform_AzureLoadBalancer_to_Any",
      "NSRC_RFC1918Priv_10_0_0_0_8_to_Any",
      "NSRC_RFC1918Priv_172_16_0_0_12_to_Any",
      "NSRC_RFC1918Priv_192_168_0_0_16_to_Any",
      "NSRC_Any_to_Any",
      "NSRC_RFC1918Priv_10_0_0_0_8_to_Any_Outbound",
      "NSRC_RFC1918Priv_172_16_0_0_12_to_Any_Outbound",
      "NSRC_RFC1918Priv_192_168_0_0_16_to_Any_Outbound",
      "NSRC_Any_to_Any_Outbound"
    ]
    default_outbound_access_enabled               = false
    private_endpoint_network_policies             = "Enabled"
    private_link_service_network_policies_enabled = false
  }
}

## Domain Controllers ##
# VM keys are global instance numbers per HLD (03, 04 for Central US)
# Names will be: A3PW000DC03, A3PW000DC04
vms = {
  "03" = {
    zone     = "1"
    sku_size = "Standard_B2ms"
    network_interfaces = {
      nic1 = {
        ip_configurations = {
          ipconfig1 = {
            private_ip_address_allocation = "Dynamic"
            #private_ip_subnet_resource_id = "/subscriptions/1e252880-b8b1-4a01-ba10-f5d50dde8044/resourceGroups/rg-eus2-man-prd-spoke-swh/providers/Microsoft.Network/virtualNetworks/vnet-eus2-man-prd-spoke-swh/subnets/subn-management-1"
            # Use the explicitly provided subnet ID if available; fallback to default AD subnet (local.ad_subnet_id) if not specified, This also allows assigning the IP (including secondary IPs) to a specific subnet.
          }
        }
      }
    }
    data_disks = {
      disk1 = {
        lun                  = 0
        disk_size_gb         = 36
        storage_account_type = "StandardSSD_LRS"
        caching              = "ReadOnly"
      }
    }
  },
  "04" = {
    zone     = "3"
    sku_size = "Standard_B2ms"
    network_interfaces = {
      nic1 = {
        ip_configurations = {
          ipconfig1 = {
            private_ip_address_allocation = "Dynamic"
            #private_ip_subnet_resource_id = "/subscriptions/1e252880-b8b1-4a01-ba10-f5d50dde8044/resourceGroups/rg-eus2-man-prd-spoke-swh/providers/Microsoft.Network/virtualNetworks/vnet-eus2-man-prd-spoke-swh/subnets/subn-management-1"
            # Use the explicitly provided subnet ID if available; fallback to default AD subnet (local.ad_subnet_id) if not specified, This also allows assigning the IP (including secondary IPs) to a specific subnet.
          }
        }
      }
    }
    data_disks = {
      disk1 = {
        lun                  = 0
        disk_size_gb         = 36
        storage_account_type = "StandardSSD_LRS"
        caching              = "None"
      }
    }
  }
}

vm_settings = {
  encryption_at_host_enabled = true
}
