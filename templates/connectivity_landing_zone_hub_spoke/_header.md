# Stacks Azure Platform Landing Zone - Connectivity - Hub and Spoke

Deploys hub virtual networks using Azure Verified Modules (AVM). Supports single or multi-region deployments with automatic IP allocation and CAF-compliant naming by default.

## Features

**Enabled by default:**

- Hub virtual networks with mesh peering (multi-region)
- Azure Firewall with firewall policies
- Private DNS zones for Private Link
- Private DNS Resolver

**Optional (disabled by default):**

- Azure Bastion hosts
- VPN Gateway
- ExpressRoute Gateway
- DDoS Protection Plan

## Quick Start

```hcl
company_name                 = "ensono"
connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"

hubs = {
  uksouth = {}
  ukwest  = {}
}
```

## Adding Hubs

Add regions to the `hubs` map. IP addresses are calculated automatically.

```hcl
hubs = {
  uksouth     = {}
  ukwest      = {}
  northeurope = { features = { bastion = true } }
}
```

## Custom Features

```hcl
hubs = {
  uksouth = {
    features = {
      firewall     = true   # default
      bastion      = false  # default
      vpn_gateway  = false  # default
    }
    address_space = "172.16.0.0/16"  # override auto-allocation
  }
}
```

## Availability Zones

Enable availability zones for higher SLA (99.99%) at the cost of cross-zone data transfer charges (~£0.01/GB):

```hcl
hubs = {
  uksouth = {
    features = {
      availability_zones = ["1", "2", "3"]
    }
  }
}
```

**Note:** Zones are disabled by default for cost optimization.
