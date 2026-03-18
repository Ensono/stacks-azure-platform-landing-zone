locals {
  # Standard Ensono NSG rules (without Ensono Management addresses per Jon Walker)
  # Based on stacks-ignite-rft-futures pattern
  common_nsg_rules = {
  # Inbound Rules
  NSRC_Platform_AzureLoadBalancer_to_Any = {
      name                       = "NSRC-Platform-AzureLoadBalancer-to-Any"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
  }
  NSRC_RFC1918Priv_10_0_0_0_8_to_Any = {
      name                       = "NSRC-RFC1918Priv-10.0.0.0_8-to-Any"
      priority                   = 400
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "10.0.0.0/8"
      destination_address_prefix = "*"
  }
  NSRC_RFC1918Priv_172_16_0_0_12_to_Any = {
      name                       = "NSRC-RFC1918Priv-172.16.0.0_12-to-Any"
      priority                   = 500
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "172.16.0.0/12"
      destination_address_prefix = "*"
  }
  NSRC_RFC1918Priv_192_168_0_0_16_to_Any = {
      name                       = "NSRC-RFC1918Priv-192.168.0.0_16-to-Any"
      priority                   = 600
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "192.168.0.0/16"
      destination_address_prefix = "*"
  }
  NSRC_Any_to_Any = {
      name                       = "NSRC-Any-to-Any"
      priority                   = 700
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
  }
  # Outbound Rules
  NSRC_RFC1918Priv_10_0_0_0_8_to_Any_Outbound = {
      name                       = "NSRC-RFC1918Priv-10.0.0.0_8-to-Any-Outbound"
      priority                   = 800
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "10.0.0.0/8"
      destination_address_prefix = "*"
  }
  NSRC_RFC1918Priv_172_16_0_0_12_to_Any_Outbound = {
      name                       = "NSRC-RFC1918Priv-172.16.0.0_12-to-Any-Outbound"
      priority                   = 900
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "172.16.0.0/12"
      destination_address_prefix = "*"
  }
  NSRC_RFC1918Priv_192_168_0_0_16_to_Any_Outbound = {
      name                       = "NSRC-RFC1918Priv-192.168.0.0_16-to-Any-Outbound"
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "192.168.0.0/16"
      destination_address_prefix = "*"
  }
  NSRC_Any_to_Any_Outbound = {
      name                       = "NSRC-Any-to-Any-Outbound"
      priority                   = 1100
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
  }
  }

  # Azure Bastion specific NSG rules
  bastion_nsg_rules = {
  AllowHttpsInbound = {
      name                       = "AllowHttpsInbound"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
  }
  AllowGatewayManagerInbound = {
      name                       = "AllowGatewayManagerInbound"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
  }
  AllowAzureLoadBalancerInbound = {
      name                       = "AllowAzureLoadBalancerInbound"
      priority                   = 140
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
  }
  AllowBastionHostCommunicationInbound = {
      name                       = "AllowBastionHostCommunicationInbound"
      priority                   = 150
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "8080"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
  }
  AllowBastionHostCommunicationInbound8080 = {
      name                       = "AllowBastionHostCommunicationInbound8080"
      priority                   = 151
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "8080"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
  }
  AllowBastionHostCommunicationInbound5701 = {
      name                       = "AllowBastionHostCommunicationInbound5701"
      priority                   = 152
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "5701"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
  }
  AllowSshOutbound = {
      name                       = "AllowSshOutbound"
      priority                   = 161
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
  }
  AllowRdpOutbound = {
      name                       = "AllowRdpOutbound"
      priority                   = 162
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
  }
  AllowAzureCloudCommunicationOutbound = {
      name                       = "AllowAzureCloudCommunicationOutbound"
      priority                   = 170
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
  }
  AllowBastionHostCommunicationOutbound8080 = {
      name                       = "AllowBastionHostCommunicationOutbound8080"
      priority                   = 180
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "8080"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
  }
  AllowBastionHostCommunicationOutbound5701 = {
      name                       = "AllowBastionHostCommunicationOutbound5701"
      priority                   = 181
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "5701"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
  }
  AllowGetSessionInformationOutbound = {
      name                       = "AllowGetSessionInformationOutbound"
      priority                   = 190
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
  }
  }

  # Merge common NSG rules with any additional rules and bastion rules
  vnet_nsg_rules = merge(local.common_nsg_rules, local.bastion_nsg_rules, var.vnet_nsg_rules)
}
#   # Determine current region from azure_location variable for DNS server prioritization
#   current_region = var.azure_location == "eastus2" ? "eastus2" : "centralus"

#   # Region-prioritized DNS servers - local region first, remote region as backup
#   region_dns_servers = {
#     eastus2   = try(local.identity_remote_states["eastus2"].outputs.private_dns_resolver_inbound_ip_addresses, [])
#     centralus = try(local.identity_remote_states["centralus"].outputs.private_dns_resolver_inbound_ip_addresses, [])
#   }

#   # Ordered DNS servers: current region first, then remote region
#   ordered_dns_servers = concat(
#     # Primary region DNS servers (current region first) - handle both string and list
#     length(local.region_dns_servers[local.current_region]) > 0 ? (
#       can(tolist(local.region_dns_servers[local.current_region])) ?
#       tolist(local.region_dns_servers[local.current_region]) :
#       [local.region_dns_servers[local.current_region]]
#     ) : [],
#     # Secondary region DNS servers (remote region as backup)
#     flatten([for region, servers in local.region_dns_servers : (
#       length(servers) > 0 ? (
#         can(tolist(servers)) ? tolist(servers) : [servers]
#       ) : []
#     ) if region != local.current_region]),
#     # Additional custom DNS servers from vnet integration
#     flatten([for k, v in var.vnet_remote_network_integration : (
#       v.custom_dns_servers != null && length(v.custom_dns_servers) > 0 ? (
#         can(tolist(v.custom_dns_servers)) ? tolist(v.custom_dns_servers) : [v.custom_dns_servers]
#       ) : []
#     )])
#   )

#   cross_region_dns_servers = {
#     dns_servers = toset(local.ordered_dns_servers)
#   }
# }
