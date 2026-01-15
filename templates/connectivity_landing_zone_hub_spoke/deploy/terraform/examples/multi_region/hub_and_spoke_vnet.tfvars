# =============================================================================
# Connectivity Hub-Spoke - Multi-Region Example
# =============================================================================
#
# This example demonstrates a production multi-region hub-spoke deployment with:
#
#   - Two hub regions (UK South and UK West)
#   - Azure Firewall with forced tunneling support
#   - Private DNS zones for Azure Private Link
#   - Private DNS Resolver for hybrid DNS
#   - Mesh VNet peering between hubs
#
# GETTING STARTED:
# ----------------
# 1. Copy this file to the root terraform directory as terraform.tfvars
# 2. Update connectivity_subscription_id with your subscription
# 3. Change hub regions to match your deployment locations
# 4. Run: terraform init && terraform plan
#
# =============================================================================

# -----------------------------------------------------------------------------
# Required Settings
# -----------------------------------------------------------------------------

# Company identifier (first 3 characters used in resource names)
# Example: "ensono" → "ens" → "rg-ens-uks-dev-hub-001"
company_name = "ensono"

# Azure subscription for deploying hub resources
# Set via environment variable: TF_VAR_connectivity_subscription_id

# -----------------------------------------------------------------------------
# Hub Configuration
# -----------------------------------------------------------------------------
#
# Each key is an Azure region where a hub will be deployed.
# Hubs are automatically connected via mesh VNet peering.
#
# IP ADDRESSING (automatic):
# Each hub receives a /16 address space based on order:
#   - First hub:  10.0.0.0/16
#   - Second hub: 10.1.0.0/16
#
# Within each /16, a /22 is carved for the hub VNet with subnets:
#   - AzureFirewallSubnet:           /26 (64 IPs)
#   - AzureFirewallManagementSubnet: /26 (64 IPs)
#   - AzureBastionSubnet:            /26 (64 IPs)
#   - GatewaySubnet:                 /27 (32 IPs)
#   - PrivateDnsResolverSubnet:      /28 (16 IPs)
#
hubs = {
  # -------------------------------------------------------------------------
  # Primary Hub
  # -------------------------------------------------------------------------
  uksouth = {
    # Default features enabled:
    # - Azure Firewall with management IP (forced tunneling)
    # - Private DNS zones for Private Link
    # - Private DNS Resolver
    # - VM auto-registration DNS zone

    # Uncomment to enable optional features:
    # features = {
    #   bastion              = true  # Azure Bastion for secure VM access
    #   vpn_gateway          = true  # Site-to-Site/Point-to-Site VPN
    #   expressroute_gateway = true  # ExpressRoute connectivity
    #   availability_zones   = ["1", "2", "3"]  # 99.99% SLA (adds cross-zone costs)
    # }

    # Uncomment to use custom IP ranges:
    # address_space = "172.16.0.0/16"
    # subnets = {
    #   firewall_address_prefix            = "172.16.0.0/26"
    #   firewall_management_address_prefix = "172.16.0.64/26"
    #   bastion_address_prefix             = "172.16.0.128/26"
    #   gateway_address_prefix             = "172.16.0.192/27"
    #   private_dns_resolver_address_prefix = "172.16.0.224/28"
    # }
  }

  # -------------------------------------------------------------------------
  # Secondary Hub
  # -------------------------------------------------------------------------
  ukwest = {
    # Secondary hub for disaster recovery / high availability
    # Mesh peering is automatically configured between all hubs
  }

  # -------------------------------------------------------------------------
  # Additional Regions (uncomment to add more hubs)
  # -------------------------------------------------------------------------
  # northeurope = {
  #   features = {
  #     bastion = true
  #   }
  # }
}

# -----------------------------------------------------------------------------
# Global Network Settings
# -----------------------------------------------------------------------------

# Base address space for automatic IP allocation (default: 10.0.0.0/8)
# Each hub receives a /16 from this range
# hub_network_address_prefix = "10.0.0.0/8"

# DDoS Protection Plan (shared across all hubs)
# NOTE: Significant cost (~£2,350/month base). Enable only if required.
ddos_protection_plan = {
  enabled = false
}

# =============================================================================
# Advanced Configuration Examples
# =============================================================================
#
# DISABLE A HUB (keep config but don't deploy):
# ---------------------------------------------
# hubs = {
#   uksouth = {}
#   ukwest = { enabled = false }
# }
#
# CUSTOM RESOURCE NAMES:
# ----------------------
# hubs = {
#   uksouth = {
#     name_overrides = {
#       resource_group  = "rg-network-hub-prod"
#       virtual_network = "vnet-hub-prod"
#       firewall        = "fw-hub-prod"
#     }
#   }
# }
#
# CUSTOM DNS ZONE NAME:
# ---------------------
# hubs = {
#   uksouth = {
#     dns = {
#       auto_registration_zone_name = "uksouth.corp.ensono.com"
#     }
#   }
# }
#
# CUSTOM SUBNETS IN HUB:
# ----------------------
# hubs = {
#   uksouth = {
#     custom_subnets = {
#       management = {
#         name             = "snet-management"
#         address_prefixes = ["10.0.4.0/24"]
#       }
#       shared_services = {
#         name             = "snet-shared"
#         address_prefixes = ["10.0.5.0/24"]
#       }
#     }
#   }
# }
#
# HUB-SPECIFIC TAGS:
# ------------------
# hubs = {
#   uksouth = {
#     tags = {
#       region_role = "primary"
#     }
#   }
#   ukwest = {
#     tags = {
#       region_role = "secondary"
#     }
#   }
# }
#
