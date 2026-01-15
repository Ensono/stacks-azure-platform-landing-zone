# =============================================================================
# Hub and Spoke Virtual Network Module
# =============================================================================
#
# Deploys Azure hub virtual networks using the Azure Verified Module (AVM).
# This module creates:
#   - Hub virtual networks with peering (if multi-region)
#   - Azure Firewall with firewall policies
#   - Azure Bastion hosts
#   - VPN and ExpressRoute gateways
#   - Private DNS zones and resolvers
#   - Route tables for hub traffic
#
# Configuration is built in locals.hubs.tf from the simplified var.hubs input.
#
# CUSTOMIZATION:
# --------------
# - To add features: Modify locals.hubs.tf hub_virtual_networks
# - To change defaults: Update variables.hubs.tf
# - For advanced scenarios: Use hub.custom_subnets or hub.name_overrides
#
# =============================================================================

module "hub_and_spoke_vnet" {
  source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
  version = "0.16.8"

  # Hub configuration built from var.hubs
  hub_virtual_networks            = local.hub_virtual_networks
  hub_and_spoke_networks_settings = local.hub_and_spoke_settings

  # Telemetry and tags
  enable_telemetry = var.enable_avm_telemetry
  tags             = local.tags
}
