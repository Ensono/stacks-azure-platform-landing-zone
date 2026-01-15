# Multi-Region Hub-Spoke Example

This example deploys a **multi-region hub-spoke network topology** - the recommended architecture for production workloads requiring high availability and disaster recovery.

## Architecture

```text
                    ┌─────────────────────────────────────┐
                    │         Mesh VNet Peering           │
                    └─────────────────────────────────────┘
                                     │
           ┌─────────────────────────┼─────────────────────────┐
           │                         │                         │
           ▼                         ▼                         ▼
    ┌─────────────┐           ┌─────────────┐           ┌─────────────┐
    │  Hub South  │           │  Hub West   │           │  Hub N...   │
    │  10.0.0.0/16│           │  10.1.0.0/16│           │  10.n.0.0/16│
    ├─────────────┤           ├─────────────┤           ├─────────────┤
    │ ✓ Firewall  │           │ ✓ Firewall  │           │ ✓ Firewall  │
    │ ✓ DNS Zones │           │ ✓ DNS Zones │           │ ✓ DNS Zones │
    │ ○ Bastion   │           │ ○ Bastion   │           │ ○ Bastion   │
    │ ○ VPN GW    │           │ ○ VPN GW    │           │ ○ VPN GW    │
    └─────────────┘           └─────────────┘           └─────────────┘
```

✓ = Enabled by default | ○ = Optional

## Quick Start

```bash
# 1. Copy example to root terraform directory
cp hub_and_spoke_vnet.tfvars ../../terraform.tfvars

# 2. Edit terraform.tfvars:
#    - Set connectivity_subscription_id
#    - Change hub regions (uksouth/ukwest) to your preferred locations
#    - Adjust features as needed

# 3. Initialize and deploy
eirctl infrastructure:plan
eirctl infrastructure:apply
```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `company_name` | Company identifier (first 3 chars used in names) | `"Ensono"` |
| `connectivity_subscription_id` | Subscription for hub resources | `"12345678-..."` |
| `hubs` | Map of hub configurations keyed by region | `{ uksouth = {}, ukwest = {} }` |

### Hub Features

Each hub can enable/disable these components:

| Feature | Default | Description |
|---------|---------|-------------|
| `firewall` | `true` | Azure Firewall for network security |
| `firewall_management_ip` | `true` | Management IP for forced tunneling |
| `private_dns_zones` | `true` | Private Link DNS zones |
| `private_dns_resolver` | `true` | DNS resolver for hybrid scenarios |
| `auto_registration_zone` | `true` | VM DNS auto-registration |
| `bastion` | `false` | Azure Bastion for VM access |
| `vpn_gateway` | `false` | VPN Gateway (S2S/P2S) |
| `expressroute_gateway` | `false` | ExpressRoute Gateway |
| `availability_zones` | `null` | Zones for 99.99% SLA |

### Example: Enable Bastion in Primary Hub

```hcl
hubs = {
  uksouth = {
    features = {
      bastion = true
    }
  }
  ukwest = {}
}
```

### Example: Custom IP Ranges

```hcl
hubs = {
  uksouth = {
    address_space = "172.16.0.0/16"
    subnets = {
      firewall_address_prefix = "172.16.0.0/26"
      bastion_address_prefix  = "172.16.0.64/26"
    }
  }
  ukwest = {
    address_space = "172.17.0.0/16"
  }
}
```

## What Gets Deployed

### Per Hub (each region)

- Resource Group for hub resources
- Virtual Network with required subnets
- Azure Firewall with policy
- Route tables for firewall routing
- VNet peering to other hubs (mesh)
- Optional: Bastion, VPN Gateway, ExpressRoute Gateway

### Shared Resources (primary region)

- Private DNS zones for Azure Private Link services
- Private DNS Resolver for hybrid DNS
- Optional: DDoS Protection Plan

## Estimated Costs

| Component | Monthly Cost (approx) |
|-----------|----------------------|
| Azure Firewall (Basic) | ~£720/hub |
| Azure Firewall (Standard) | ~£800/hub |
| Azure Bastion (Basic) | ~£110/hub |
| VPN Gateway (VpnGw1) | ~£110/hub |
| ExpressRoute Gateway | ~£110/hub |
| DDoS Protection Plan | ~£2,350 (global) |

*Costs vary by region and configuration. Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate estimates.*

## Files

| File | Description |
|------|-------------|
| [hub_and_spoke_vnet.tfvars](./hub_and_spoke_vnet.tfvars) | Example configuration - copy to `terraform.tfvars` |

## See Also

- [Single Region Example](../single_region/) - Simpler deployment (not recommended for production)
- [Module Variables](../../variables.hubs.tf) - Full variable documentation
