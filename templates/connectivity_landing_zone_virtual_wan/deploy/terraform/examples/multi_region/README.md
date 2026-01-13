# Connectivity Landing Zone Example - Full Multi-Region

This example configuration deploys a full multi-region connectivity landing zone with:

- Hub Networking with Virtual WAN
- Private DNS Zones for Private Link
- Optional DDOS Protection Plan
- Azure Firewall

## Options

There are two options for deploying the hub networking:

| File | Description |
|------|-------------|
| [virtual_wan_minimal.tfvars](./virtual_wan_minimal.tfvars) | Uses module defaults for resource names and IP address ranges. Only defines resource group names, feature toggles, and high-level address spaces (e.g., `10.0.0.0/16`). Best for quick starts or when you're happy with default naming. |
| [virtual_wan.tfvars](./virtual_wan.tfvars) | Fully customized configuration with explicit names for all resources (Virtual WAN, hubs, firewalls, gateways, sidecar VNets, etc.) and detailed subnet-level IP address prefixes. Best for production deployments requiring specific naming conventions or precise network segmentation. |
