# =============================================================================
# Resource Naming Module
# =============================================================================
#
# Uses the Azure CAF naming module to generate consistent, compliant names
# for all resources. Names include the region short code (e.g., "uks")
# following Cloud Adoption Framework best practices.
#
# NAMING PATTERN:
# ---------------
# {resource_type}-{company_prefix}-{region_code}-{environment}-{component}-{instance}
#
# COMPONENTS (per region):
# ------------------------
# - hub:         Hub virtual network and resource group
# - hub-fw:      Azure Firewall and firewall policy
# - hub-fw-mgmt: Firewall management public IP (forced tunneling)
# - hub-bas:     Azure Bastion host
# - hub-vpn:     VPN Gateway
# - hub-er:      ExpressRoute Gateway
# - hub-std:     Route table for user subnets
#
# COMPONENTS (primary region only):
# ---------------------------------
# - hub-dns:  Private DNS zones and resolvers
# - hub-ddos: DDoS protection plan
#
# Examples:
#   rg-ens-uks-dev-hub-001         (Hub Resource Group in UK South)
#   vnet-ens-uks-dev-hub-001       (Hub Virtual Network in UK South)
#   fw-ens-uks-dev-hub-fw-001      (Azure Firewall in UK South)
#   rg-ens-uks-dev-hub-dns-001     (DNS Resource Group in UK South)
#   rg-ens-uks-dev-hub-ddos-001    (DDoS Resource Group in UK South)
#
# CUSTOMIZATION:
# --------------
# To override auto-generated names, use the `name_overrides` attribute in
# the hub configuration. See variables.hubs.tf for details.
#
# To change the naming pattern entirely, replace this module with your own
# naming implementation and update locals.hubs.tf accordingly.
#
# =============================================================================

# -----------------------------------------------------------------------------
# Naming Instances
# -----------------------------------------------------------------------------
# Builds a map of all naming instances needed. Each entry specifies:
#   - component: The component name for the suffix (e.g., "hub", "hub-fw")
#   - region: The Azure region for geo_code lookup
#
# Per-region components: hub, hub-fw (one instance per hub region)
# Shared components: hub-dns, hub-ddos (primary region only)
#
locals {
  naming_instances = merge(
    # Hub naming - one per region
    { for region in keys(local.enabled_hubs) : "hub-${region}" => {
      component = "hub"
      region    = region
    } },
    # Firewall naming - one per region
    { for region in keys(local.enabled_hubs) : "hub-fw-${region}" => {
      component = "hub-fw"
      region    = region
    } },
    # Firewall management naming - one per region
    { for region in keys(local.enabled_hubs) : "hub-fw-mgmt-${region}" => {
      component = "hub-fw-mgmt"
      region    = region
    } },
    # Bastion naming - one per region
    { for region in keys(local.enabled_hubs) : "hub-bas-${region}" => {
      component = "hub-bas"
      region    = region
    } },
    # VPN naming - one per region
    { for region in keys(local.enabled_hubs) : "hub-vpn-${region}" => {
      component = "hub-vpn"
      region    = region
    } },
    # ExpressRoute naming - one per region
    { for region in keys(local.enabled_hubs) : "hub-er-${region}" => {
      component = "hub-er"
      region    = region
    } },
    # Route Table User Subnets naming - one per region
    { for region in keys(local.enabled_hubs) : "hub-std-${region}" => {
      component = "hub-std"
      region    = region
    } },
    # DNS naming - primary region only
    { "hub-dns" = {
      component = "hub-dns"
      region    = local.primary_hub_region
    } },
    # DDoS naming - primary region only
    { "hub-ddos" = {
      component = "hub-ddos"
      region    = local.primary_hub_region
    } }
  )
}

# -----------------------------------------------------------------------------
# Azure Naming Module
# https://registry.terraform.io/modules/Azure/naming/azurerm/latest
# -----------------------------------------------------------------------------
module "naming" {
  source   = "Azure/naming/azurerm"
  version  = "0.4.3"
  for_each = local.naming_instances

  suffix = [
    substr(var.company_name, 0, 3),                                   # Company: "ens"
    module.azure_regions.regions_by_name[each.value.region].geo_code, # Region: "uks"
    terraform.workspace,                                              # Environment: "prd"
    each.value.component,                                             # Component: "hub", "hub-fw", etc.
    "001"
  ]
}

# =============================================================================
# Usage Examples (for reference)
# =============================================================================
#
# Hub resources (per region):
#   module.naming["hub-uksouth"].resource_group.name      → rg-ens-uks-dev-hub-001
#   module.naming["hub-uksouth"].virtual_network.name     → vnet-ens-uks-dev-hub-001
#   module.naming["hub-uksouth"].bastion_host.name        → bas-ens-uks-dev-hub-001
#
# Firewall resources (per region):
#   module.naming["hub-fw-uksouth"].firewall.name         → fw-ens-uks-dev-hub-fw-001
#   module.naming["hub-fw-uksouth"].firewall_policy.name  → fwp-ens-uks-dev-hub-fw-001
#
# Shared DNS resources:
#   module.naming["hub-dns"].resource_group.name          → rg-ens-uks-dev-hub-dns-001
#   module.naming["hub-dns"].private_dns_resolver.name    → dnspr-ens-uks-dev-hub-dns-001
#
# Shared DDoS resources:
#   module.naming["hub-ddos"].resource_group.name         → rg-ens-uks-dev-hub-ddos-001
#   module.naming["hub-ddos"].network_ddos_protection_plan.name → ddospp-ens-uks-dev-hub-ddos-001
#
