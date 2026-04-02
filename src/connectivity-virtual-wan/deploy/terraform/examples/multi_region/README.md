# Multi-Region Virtual WAN Example

This example deploys a **multi-region Virtual WAN topology** - the recommended architecture for production workloads requiring high availability and disaster recovery.

## Architecture

```mermaid
flowchart TB
    subgraph vwan["Virtual WAN (Global)"]
        direction LR

        subgraph hubSouth["Virtual Hub UK South (10.0.0.0/23)"]
            direction TB
            fw1["✓ Firewall"]
            vpn1["○ VPN Gateway"]
            er1["○ ExpressRoute"]
        end

        subgraph hubWest["Virtual Hub UK West (10.1.0.0/23)"]
            direction TB
            fw2["✓ Firewall"]
            vpn2["○ VPN Gateway"]
            er2["○ ExpressRoute"]
        end

        hubSouth <--> hubWest
    end

    subgraph sidecarSouth["Sidecar VNet UK South (10.0.4.0/22)"]
        direction TB
        dns1["✓ DNS Zones"]
        resolver1["✓ DNS Resolver"]
        autoreg1["✓ Auto-Reg Zone"]
        pe1["✓ PE Subnet"]
        bas1["○ Bastion"]
    end

    subgraph sidecarWest["Sidecar VNet UK West (10.1.4.0/22)"]
        direction TB
        dns2["✓ DNS Zones"]
        resolver2["○ DNS Resolver"]
        autoreg2["✓ Auto-Reg Zone"]
        pe2["✓ PE Subnet"]
        bas2["○ Bastion"]
    end

    ampls["✓ Azure Monitor Private Link"]
    ddos["○ DDoS Protection Plan"]

    hubSouth --> sidecarSouth
    hubWest --> sidecarWest
    ampls --> sidecarSouth
    ampls --> sidecarWest
    ddos -.-> vwan

    style vwan fill:#f5f5f5,stroke:#d0d0d0
    style hubSouth fill:#0078D4,stroke:#005A9E,color:#fff
    style hubWest fill:#0078D4,stroke:#005A9E,color:#fff
    style sidecarSouth fill:#50E6FF,stroke:#0078D4,color:#000
    style sidecarWest fill:#50E6FF,stroke:#0078D4,color:#000
    style fw1 fill:#107C10,stroke:#0B5C0B,color:#fff
    style fw2 fill:#107C10,stroke:#0B5C0B,color:#fff
    style dns1 fill:#107C10,stroke:#0B5C0B,color:#fff
    style dns2 fill:#107C10,stroke:#0B5C0B,color:#fff
    style resolver1 fill:#107C10,stroke:#0B5C0B,color:#fff
    style resolver2 fill:#605E5C,stroke:#3B3A39,color:#fff
    style autoreg1 fill:#107C10,stroke:#0B5C0B,color:#fff
    style autoreg2 fill:#107C10,stroke:#0B5C0B,color:#fff
    style pe1 fill:#107C10,stroke:#0B5C0B,color:#fff
    style pe2 fill:#107C10,stroke:#0B5C0B,color:#fff
    style bas1 fill:#605E5C,stroke:#3B3A39,color:#fff
    style bas2 fill:#605E5C,stroke:#3B3A39,color:#fff
    style vpn1 fill:#605E5C,stroke:#3B3A39,color:#fff
    style vpn2 fill:#605E5C,stroke:#3B3A39,color:#fff
    style er1 fill:#605E5C,stroke:#3B3A39,color:#fff
    style er2 fill:#605E5C,stroke:#3B3A39,color:#fff
    style ampls fill:#107C10,stroke:#0B5C0B,color:#fff
    style ddos fill:#605E5C,stroke:#3B3A39,color:#fff
```

> [!NOTE]
> ✓ Enabled by default | ○ Optional (disabled)

## Quick Start

```bash
# 1. Copy example to root terraform directory
cp virtual_wan.tfvars ../../terraform.tfvars

# 2. Edit terraform.tfvars:
#    - Change hub regions (uksouth/ukwest) to your preferred locations
#    - Adjust features as needed

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
| `hubs` | Map of hub configurations keyed by region | `{ uksouth = {}, ukwest = {} }` |

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|--------|
| `TF_VAR_connectivity_subscription_id` | Subscription for hub resources | `00000000-0000-0000-0000-000000000000` |

### Hub Features

Each hub can enable/disable these components:

| Feature | Default | Description |
|---------|---------|-------------|
| `firewall` | `true` | Azure Firewall (Secured Hub) |
| `firewall_sku` | `"Standard"` | Firewall SKU: Basic/Standard/Premium |
| `private_dns_zones` | `true` | Private Link DNS zones |
| `private_dns_resolver` | `false` | DNS resolver for hybrid scenarios |
| `auto_registration_zone` | `true` | VM DNS auto-registration |
| `bastion` | `false` | Azure Bastion for VM access |
| `vpn_gateway` | `false` | VPN Gateway (S2S/P2S) |
| `expressroute_gateway` | `false` | ExpressRoute Gateway |

### Module-Level Features

| Feature | Default | Description |
|---------|---------|-------------|
| `network_watcher.enabled` | `true` | Network Watcher (free) |
| `ddos_protection_plan.enabled` | `false` | DDoS Protection (~£2,200/month) |

### Example: Enable Bastion in Primary Hub

```hcl
hubs = {
  uksouth = {
    features = {
      bastion              = true
      private_dns_resolver = true
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
  }
  ukwest = {
    address_space = "172.17.0.0/16"
  }
}
```

## What Gets Deployed

### Global Resources

- Virtual WAN (Standard SKU)
- Resource Group for Virtual WAN
- Optional: DDoS Protection Plan

### Per Hub (each region)

- Resource Group for hub resources
- Virtual Hub with Secured Hub (Azure Firewall)
- Sidecar Virtual Network for ancillary services
- Azure Firewall with policy (Standard SKU by default)
- Network Watcher (free network diagnostics)
- Private Endpoints subnet
- Automatic hub-to-hub routing (no VNet peering needed)
- Optional: Bastion, VPN Gateway, ExpressRoute Gateway

### Shared Resources (primary region)

- Private DNS zones for Azure Private Link services
- Private DNS Resolver for hybrid DNS
- Azure Monitor Private Link Scope (AMPLS) with endpoints in each hub

## Estimated Costs

| Component | Monthly Cost (approx) |
|-----------|----------------------|
| Virtual Hub | ~£240/hub |
| Azure Firewall (Basic) | ~£180/hub |
| Azure Firewall (Standard) | ~£720/hub |
| Azure Firewall (Premium) | ~£800/hub |
| Azure Bastion (Basic) | ~£110/hub |
| VPN Gateway (VpnGw1) | ~£110/hub |
| ExpressRoute Gateway | ~£110/hub |
| Private DNS Resolver | ~£145 |
| AMPLS Private Endpoint | ~£7/hub |
| DDoS Protection Plan | ~£2,200 (global) |

*Costs vary by region and configuration. Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate estimates.*

## Files

| File | Description |
|------|-------------|
| [virtual_wan.tfvars](./virtual_wan.tfvars) | Example configuration - copy to `terraform.tfvars` |

## See Also

- [Single Region Example](../single_region/) - Simpler deployment (not recommended for production)
- [Module Variables](../../variables_hubs.tf) - Full variable documentation
