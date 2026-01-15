# =============================================================================
# Connectivity Hub-Spoke - Single Region Example
# =============================================================================
#
# ⚠️  WARNING: Single-region deployments are NOT recommended for production.
#     Consider the multi-region example for high availability and disaster
#     recovery capabilities.
#
# This example demonstrates a minimal single-region hub-spoke deployment with:
#
#   - One hub region
#   - Azure Firewall with forced tunneling support
#   - Private DNS zones for Azure Private Link
#   - Private DNS Resolver for hybrid DNS
#
# USE CASES:
# ----------
# - Development and testing environments
# - Proof of concept deployments
# - Cost-sensitive non-production workloads
#
# GETTING STARTED:
# ----------------
# 1. Copy this file to the root terraform directory as terraform.tfvars
# 2. Update connectivity_subscription_id with your subscription
# 3. Change hub region to match your deployment location
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
# Single hub deployment - change the region key to your preferred location.
#
# IP ADDRESSING (automatic):
# The hub receives 10.0.0.0/16 with subnets:
#   - AzureFirewallSubnet:           10.0.0.0/26
#   - AzureFirewallManagementSubnet: 10.0.0.64/26
#   - AzureBastionSubnet:            10.0.0.128/26
#   - GatewaySubnet:                 10.0.0.192/27
#   - PrivateDnsResolverSubnet:      10.0.0.224/28
#
hubs = {
  # Change 'uksouth' to your preferred region (e.g., ukwest, northeurope etc.)
  uksouth = {
    # Default features:
    # - Azure Firewall with management IP
    # - Private DNS zones
    # - Private DNS Resolver
    # - VM auto-registration DNS zone

    # Uncomment to enable optional features:
    # features = {
    #   bastion              = true  # Azure Bastion for secure VM access
    #   vpn_gateway          = true  # Site-to-Site/Point-to-Site VPN
    #   expressroute_gateway = true  # ExpressRoute connectivity
    # }
  }
}
