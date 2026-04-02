# Single-Region Hub-Spoke Example

> [!WARNING]
> **Not Recommended for Production**: Single-region deployments lack disaster recovery and high availability capabilities. Consider the [multi-region example](../multi_region/README.md) for production workloads.

This example deploys a **minimal single-region hub-spoke network** suitable for development, testing, or proof-of-concept scenarios.

## Architecture

```mermaid
flowchart TB
    subgraph hub["Hub VNet (10.0.0.0/16)"]
        direction TB
        fw["✓ Azure Firewall"]
        dns["✓ Private DNS Zones"]
        resolver["✓ DNS Resolver"]
        autoreg["✓ Auto-Registration Zone"]
        pe["✓ Private Endpoints Subnet"]
        bastion["○ Bastion"]
        vpn["○ VPN Gateway"]
        er["○ ExpressRoute Gateway"]
        zones["○ Availability Zones"]
    end

    ampls["✓ Azure Monitor Private Link"]
    ddos["○ DDoS Protection Plan"]
    ampls --> hub
    ddos -.-> hub

    style hub fill:#0078D4,stroke:#005A9E,color:#fff
    style fw fill:#107C10,stroke:#0B5C0B,color:#fff
    style dns fill:#107C10,stroke:#0B5C0B,color:#fff
    style resolver fill:#107C10,stroke:#0B5C0B,color:#fff
    style autoreg fill:#107C10,stroke:#0B5C0B,color:#fff
    style pe fill:#107C10,stroke:#0B5C0B,color:#fff
    style bastion fill:#605E5C,stroke:#3B3A39,color:#fff
    style vpn fill:#605E5C,stroke:#3B3A39,color:#fff
    style er fill:#605E5C,stroke:#3B3A39,color:#fff
    style zones fill:#605E5C,stroke:#3B3A39,color:#fff
    style ampls fill:#107C10,stroke:#0B5C0B,color:#fff
    style ddos fill:#605E5C,stroke:#3B3A39,color:#fff
```

> [!NOTE]
> ✓ Enabled by default | ○ Optional (disabled)

## Quick Start

```bash
# 1. Copy example to root terraform directory
cp hub_and_spoke_vnet.tfvars ../../terraform.tfvars

# 2. Edit terraform.tfvars:
#    - Change hub region (uksouth) to your preferred location

# 3. Set the subscription ID as an environment variable
export TF_VAR_connectivity_subscription_id=00000000-0000-0000-0000-000000000000

# 4. Initialize and deploy
eirctl infrastructure:plan
eirctl infrastructure:apply
```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `company` | Company identifier (first 3 chars used in names) | `"ensono"` |
| `hubs` | Single hub configuration | `{ uksouth = {} }` |

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|--------|
| `TF_VAR_connectivity_subscription_id` | Subscription for hub resources | `00000000-0000-0000-0000-000000000000` |

### Change Region

Simply change the map key to your preferred Azure region:

```hcl
# UK South
hubs = { uksouth = {} }

# UK West
hubs = { ukwest = {} }
```

### Enable Optional Features

```hcl
hubs = {
  uksouth = {
    features = {
      firewall_sku = "Basic"  # Cost saving: ~£180/month vs Standard ~£720/month
      bastion      = true     # Secure VM access
      vpn_gateway  = true     # On-premises connectivity
    }
  }
}
```

## What Gets Deployed

- Resource Group for hub resources
- Virtual Network with required subnets
- Azure Firewall with policy (Standard SKU by default)
- Route tables for firewall routing
- Network Watcher (free network diagnostics)
- Private DNS zones for Azure Private Link
- Private DNS Resolver
- Private Endpoints subnet (`snet-private-endpoints`)
- Azure Monitor Private Link Scope (AMPLS) with private endpoint
- Optional: Bastion, VPN Gateway, ExpressRoute Gateway, Flow Logs

## Estimated Costs

| Component | Monthly Cost (approx) |
|-----------|----------------------|
| Azure Firewall (Standard) | ~£720 |
| Azure Firewall (Basic) | ~£180 |
| Azure Bastion (Basic) | ~£110 |
| VPN Gateway (VpnGw1) | ~£110 |
| Private DNS Resolver | ~£145 |
| AMPLS Private Endpoint | ~£7 |
| Flow Logs Storage | ~£15-50 (if enabled) |

*Costs vary by region. Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate estimates.*

## Upgrading to Multi-Region

To add a second hub for high availability:

```hcl
hubs = {
  uksouth = {}   # Existing hub
  ukwest  = {}   # New secondary hub (automatically peered)
}
```

## Files

| File | Description |
|------|-------------|
| [hub_and_spoke_vnet.tfvars](./hub_and_spoke_vnet.tfvars) | Example configuration - copy to `terraform.tfvars` |

## See Also

- [Multi-Region Example](../multi_region/) - Recommended for production
- [Module Variables](../../variables.hubs.tf) - Full variable documentation
