# Stacks Azure Platform Landing Zone - Connectivity Virtual WAN

## Overview

This module deploys a Virtual WAN network topology using Azure Verified
Modules (AVM). It supports single or multi-region deployments with
automatic IP allocation and CAF-compliant naming.

Virtual WAN provides a fully managed hub infrastructure with automatic
any-to-any routing, integrating VPN and ExpressRoute gateways directly
within the virtual hub. Each hub has a companion sidecar VNet for
services such as Azure Bastion, DNS Resolver, and private endpoints that
cannot be placed inside the virtual hub itself.

``` mermaid
flowchart TB
    subgraph Internet
        PIP["Public IPs"]
    end

    subgraph VWAN["Virtual WAN"]
        direction TB

        subgraph Hub1["Virtual Hub (per region)"]
            direction TB
            VHub["Virtual Hub /23"]

            subgraph FW["Azure Firewall"]
                FWHub["Hub Firewall"]
            end

            subgraph Gateway["Gateways (optional)"]
                VPN["VPN Gateway"]
                ER["ExpressRoute"]
            end
        end

        subgraph Sidecar["Sidecar VNet (per region)"]
            Bastion["AzureBastionSubnet /26"]
            GWSubnet["GatewaySubnet /27"]
            Resolver["DNS Resolver /28"]
        end
    end

    subgraph Spokes["Spoke VNets"]
        Spoke1["App Landing Zone 1"]
        Spoke2["App Landing Zone 2"]
    end

    subgraph Management["Management Landing Zone"]
        LogAnalytics["Log Analytics"]
    end

    PIP --> FW
    FW --> Spokes
    Spokes -.-> |"VNet Connection"| Hub1
    Gateway --> |"Hybrid"| OnPrem["On-Premises"]
    Sidecar -.-> |"VNet Connection"| Hub1
    FW --> LogAnalytics
```

### Module Chain

    resource_groups → virtual_wan

1.  **resource_groups** — Deploys resource groups per hub region using
    `for_each` from configuration

2.  **virtual_wan** — Deploys the Virtual WAN, virtual hubs, firewall,
    bastion, DNS, and gateways using
    [avm-ptn-alz-connectivity-virtual-wan](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm/latest)

### Prerequisites

- Terraform \>= 1.12

- AzureRM provider \>= 4.0

- AzAPI provider \>= 2.0

- Azure subscription for connectivity resources

- Management Landing Zone deployed (for Log Analytics integration)

## Features

| Feature                    | Default | Description                                         |
|----------------------------|---------|-----------------------------------------------------|
| Virtual WAN                | ✅      | Standard SKU Virtual WAN                            |
| Virtual Hubs               | ✅      | One per region with /23 address prefix              |
| Azure Firewall             | ✅      | Standard SKU (configurable: Basic/Standard/Premium) |
| Firewall DNS Proxy         | ✅      | Enables FQDN filtering and DNS query logging        |
| Firewall Diagnostics       | ✅      | All log categories sent to Log Analytics            |
| Sidecar Virtual Network    | ✅      | For Bastion, DNS Resolver, and additional services  |
| Private DNS Zones          | ✅      | For Azure Private Link services                     |
| Private DNS Resolver       | ❌      | For hybrid DNS resolution                           |
| Azure Bastion              | ❌      | Secure VM access (in sidecar VNet)                  |
| VPN Gateway                | ❌      | Site-to-Site/Point-to-Site VPN                      |
| ExpressRoute Gateway       | ❌      | ExpressRoute connectivity                           |
| DDoS Protection Plan       | ❌      | Shared across all hubs                              |
| Flow Logs Storage          | ✅      | Per-hub storage account for NSG/VNet flow logs      |
| Azure Monitor Private Link | ✅      | AMPLS for secure monitoring connectivity            |
| Metric Alerts              | ✅      | Firewall, gateway, and virtual hub health alerts    |

## Quick Start

Minimal single-region deployment:

``` hcl
company                      = "ensono"
connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"

management_remote_state = {
  storage_account_name = "<storage-account-name>"
}

hubs = {
  uksouth = {}
}
```

### Deployment Order

1.  Deploy Management Landing Zone first (provides Log Analytics
    workspace)

2.  Deploy this module with `management_remote_state` pointing to the
    management state

### Required Environment Variable

``` bash
export ARM_SUBSCRIPTION_ID="<connectivity-subscription-id>"
```

## Architecture

### IP Address Layout

Each hub region receives a `/16` block from the `10.0.0.0/8` address
space. Within each `/16`, the virtual hub uses a `/23` prefix and the
sidecar VNet uses adjacent subnets.

| Component          | Default CIDR    | Purpose                               |
|--------------------|-----------------|---------------------------------------|
| Hub Address Space  | `10.x.0.0/16`   | Per-region address space              |
| Virtual Hub Prefix | `10.x.0.0/23`   | Virtual Hub managed address space     |
| Sidecar VNet       | `10.x.4.0/24`   | Sidecar services address space        |
| AzureBastionSubnet | `10.x.4.0/26`   | Azure Bastion (64 IPs)                |
| GatewaySubnet      | `10.x.4.64/27`  | VPN/ExpressRoute gateway (32 IPs)     |
| DNS Resolver       | `10.x.4.96/28`  | Private DNS Resolver inbound (16 IPs) |
| Private Endpoints  | `10.x.4.128/26` | AMPLS private endpoints (64 IPs)      |

### IP Allocation Algorithm

Regions are sorted alphabetically and assigned sequential `/16` blocks:

    Sorted Regions:       uksouth → ukwest
    Hub Index:            0       → 1
    Hub Address Space:    10.0.0.0/16 → 10.1.0.0/16
    Virtual Hub Prefix:   10.0.0.0/23 → 10.1.0.0/23

The module supports up to 256 regions using the `10.0.0.0/8` address
space.

### Virtual Hub vs Sidecar VNet

Unlike hub-spoke topology where all resources reside in the hub VNet,
Virtual WAN places some resources in a companion sidecar VNet:

    Virtual Hub (/23)          Sidecar VNet (/24)
    ├── Azure Firewall         ├── AzureBastionSubnet /26
    ├── VPN Gateway            ├── GatewaySubnet /27
    ├── ExpressRoute Gateway   ├── DNS Resolver /28
    └── Route Tables           └── Private Endpoints /26

The sidecar VNet is automatically connected to the virtual hub for
reachability.

## Configuration Examples

### Multi-Region Deployment

``` hcl
hubs = {
  uksouth = {}
  ukwest  = {}
}
```

IP addresses are calculated automatically (sorted alphabetically):

| Region  | Hub Address Space | Virtual Hub Prefix |
|---------|-------------------|--------------------|
| uksouth | `10.0.0.0/16`     | `10.0.0.0/23`      |
| ukwest  | `10.1.0.0/16`     | `10.1.0.0/23`      |

### Cost Optimisation for Non-Production

Use Firewall Basic SKU for dev/test environments:

``` hcl
hubs = {
  uksouth = {
    features = {
      firewall_sku = "Basic"  # ~£180/month vs Standard ~£720/month
    }
  }
}
```

| Firewall SKU | Monthly Cost | Use Case                        |
|--------------|--------------|---------------------------------|
| Basic        | ~£180        | Dev/Test, low throughput        |
| Standard     | ~£720        | Production, threat intelligence |
| Premium      | ~£800        | TLS inspection, IDPS signatures |

<div class="warning">

Firewall Basic SKU has reduced throughput (250 Mbps) and fewer features.
Not recommended for production.

</div>

### Enable Optional Features

``` hcl
hubs = {
  uksouth = {
    features = {
      bastion              = true
      vpn_gateway          = true
      expressroute_gateway = true
      private_dns_resolver = true
    }
  }
}
```

### Custom IP Addressing

``` hcl
hubs = {
  uksouth = {
    address_space = "172.16.0.0/16"
    sidecar_subnets = {
      bastion_address_prefix              = "172.16.4.0/26"
      gateway_address_prefix              = "172.16.4.64/27"
      private_dns_resolver_address_prefix = "172.16.4.96/28"
    }
  }
}
```

### Custom Resource Names

``` hcl
hubs = {
  uksouth = {
    name_overrides = {
      resource_group          = "rg-vwan-hub-prod"
      virtual_hub             = "vhub-prod-uks"
      sidecar_virtual_network = "vnet-sidecar-prod"
      firewall                = "fw-hub-prod"
    }
  }
}
```

### DDoS Protection Plan

DDoS Protection Plan is disabled by default due to significant cost
(~£2,200/month flat fee).

``` hcl
ddos_protection_plan = {
  enabled = true
}
```

### Disable a Hub Temporarily

``` hcl
hubs = {
  uksouth = {}
  ukwest  = { enabled = false }
}
```

### Production Configuration

``` hcl
hubs = {
  uksouth = {
    features = {
      firewall_sku = "Standard"
      bastion      = true
      vpn_gateway  = true
    }
  }
}

management_remote_state = {
  enabled              = true
  storage_account_name = "<storage-account-name>"
}
```

### Cost Estimation

Estimated monthly costs per hub (UK South, January 2025):

| Resource                     | Default | Monthly Cost (GBP) | Notes                          |
|------------------------------|---------|--------------------|--------------------------------|
| Virtual Hub                  | ✅      | ~£210              | Base hub cost                  |
| Azure Firewall Standard      | ✅      | ~£720              | Hub firewall                   |
| Azure Firewall Basic         | ❌      | ~£180              | Dev/test alternative           |
| VPN Gateway                  | ❌      | ~£140              | Scale unit 1                   |
| ExpressRoute Gateway         | ❌      | ~£140              | Scale unit 1                   |
| Azure Bastion Standard       | ❌      | ~£140              | 2 scale units                  |
| DDoS Protection Plan         | ❌      | ~£2,200            | Shared across subscription     |
| Log Analytics                | \-      | Variable           | ~£2/GB/month ingestion         |
| **Minimum (Hub + Firewall)** |         | **~£930**          |                                |
| **Full Production**          |         | **~£1,210**        | Hub + Firewall + VPN + Bastion |

<div class="tip">

Virtual WAN costs more than hub-spoke due to the managed hub
infrastructure, but provides simplified routing and better scalability
for large deployments.

</div>

### Comparison: Virtual WAN vs Hub-Spoke

| Aspect      | Virtual WAN                 | Hub-Spoke             |
|-------------|-----------------------------|-----------------------|
| Management  | Fully managed hub           | Self-managed VNet     |
| Routing     | Automatic any-to-any        | Manual route tables   |
| Cost        | Higher base cost            | Lower base cost       |
| Scalability | Better for large networks   | Good for small-medium |
| Hybrid      | Built-in VPN/ER integration | Manual gateway setup  |
| Complexity  | Lower operational           | Higher operational    |

**Choose Virtual WAN when:**

- You have 50+ spoke VNets

- You need global transit routing

- You want simplified VPN/ExpressRoute management

- Operational simplicity is more important than cost

**Choose Hub-Spoke when:**

- You have fewer spoke VNets

- Cost optimisation is critical

- You need granular routing control

- You have existing hub-spoke infrastructure

## Resource Naming

All resources use [CAF naming
conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
via the
[Azure/naming](https://registry.terraform.io/modules/Azure/naming/azurerm/latest)
module. Names can be overridden per hub using `name_overrides`.

### Generated Names

With `company = "ensono"` and region `uksouth`:

| Resource             | Generated Name           | Name Override Key         |
|----------------------|--------------------------|---------------------------|
| Resource Group       | `rg-hub-uksouth`         | `resource_group`          |
| Virtual WAN          | `vwan-hub-uksouth`       | \-                        |
| Virtual Hub          | `vhub-hub-uksouth`       | `virtual_hub`             |
| Sidecar VNet         | `vnet-hub-uksouth`       | `sidecar_virtual_network` |
| Firewall             | `afw-hub-uksouth`        | `firewall`                |
| Firewall Policy      | `afwp-hub-uksouth`       | `firewall_policy`         |
| Bastion Host         | `bas-hub-bas-uksouth`    | `bastion`                 |
| VPN Gateway          | `vwan-hub-vpn-uksouth`   | `vpn_gateway`             |
| ExpressRoute Gateway | `vwan-hub-er-uksouth`    | `expressroute_gateway`    |
| DNS Resolver         | `dnspr-hub-dns-uksouth`  | `private_dns_resolver`    |
| Flow Logs Storage    | `st<unique>hubfluksouth` | \-                        |

### Naming Pattern

Names follow the pattern: `{caf_prefix}-{company}-{component}-{region}`

The module uses `substr(var.company, 0, 5)` to limit the company prefix
length, ensuring resource names stay within Azure limits.

## Module Integration

### Management Landing Zone

This module integrates with the Management Landing Zone to enable
firewall diagnostics, centralized monitoring, and alerting. Configure
the remote state backend to fetch the Log Analytics workspace ID.

``` hcl
management_remote_state = {
  storage_account_name = "<storage-account-name>"
}
```

When the management remote state is configured, the module
automatically:

- Sends firewall diagnostic logs to Log Analytics

- Sends bastion diagnostic logs to Log Analytics

- Sends gateway diagnostic logs to Log Analytics

- Deploys metric alerts for firewall, gateways, and virtual hubs

- Configures Azure Monitor Private Link Scope (AMPLS)

### Spoke Integration

Spoke VNets connect to Virtual WAN through VNet connections, which
provide automatic routing without manual route table management.

#### VNet Connection

``` hcl
resource "azurerm_virtual_hub_connection" "spoke" {
  name                      = "conn-spoke-app"
  virtual_hub_id            = "<virtual-hub-id>"
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  routing {
    associated_route_table_id = "<default-route-table-id>"
  }
}
```

#### Private DNS Zone Links

``` hcl
resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  name                  = "link-spoke-app"
  resource_group_name   = "<dns-zone-resource-group>"
  private_dns_zone_name = "privatelink.blob.core.windows.net"
  virtual_network_id    = azurerm_virtual_network.spoke.id
}
```

### Available Outputs

| Output                                 | Description                               |
|----------------------------------------|-------------------------------------------|
| `virtual_wan_id`                       | Virtual WAN resource ID                   |
| `virtual_hub_resource_ids`             | Virtual Hub IDs, keyed by region          |
| `firewall_resource_ids`                | Firewall IDs, keyed by region             |
| `firewall_private_ip_addresses`        | Firewall private IPs, keyed by region     |
| `vpn_gateway_resource_ids`             | VPN Gateway IDs, keyed by region          |
| `express_route_gateway_resource_ids`   | ExpressRoute Gateway IDs, keyed by region |
| `sidecar_virtual_network_resource_ids` | Sidecar VNet IDs, keyed by region         |
| `private_dns_zone_resource_ids`        | DNS Zone IDs, keyed by region             |
| `resource_group_ids`                   | Resource Group IDs, keyed by purpose      |

## Metric Alerts

Metric alerts are deployed when a Log Analytics workspace ID is
available (via management remote state or direct configuration). Alerts
target firewalls, gateways, and virtual hubs.

### Firewall Alerts

| Alert                | Severity     | Metric                | Condition   |
|----------------------|--------------|-----------------------|-------------|
| Health degradation   | 1 (Critical) | `FirewallHealth`      | \< 100%     |
| SNAT port exhaustion | 2 (Warning)  | `SNATPortUtilization` | \> 80%      |
| High throughput      | 2 (Warning)  | `Throughput`          | \> 2.5 Gbps |

### VPN Gateway Alerts

| Alert                 | Severity     | Metric                   | Condition |
|-----------------------|--------------|--------------------------|-----------|
| Tunnel bandwidth drop | 2 (Warning)  | `TunnelAverageBandwidth` | \< 1 bps  |
| BGP peer status       | 1 (Critical) | `BgpPeerStatus`          | \< 1      |

### ExpressRoute Gateway Alerts

| Alert           | Severity    | Metric                               | Condition |
|-----------------|-------------|--------------------------------------|-----------|
| Traffic drop    | 2 (Warning) | `ErGatewayConnectionBitsInPerSecond` | \< 1 bps  |
| CPU utilisation | 2 (Warning) | `ExpressRouteGatewayCpuUtilization`  | \> 80%    |

### Virtual Hub Alerts

| Alert           | Severity     | Metric                    | Condition |
|-----------------|--------------|---------------------------|-----------|
| Data processed  | 2 (Warning)  | `VirtualHubDataProcessed` | \> 500 GB |
| BGP peer status | 1 (Critical) | `BgpPeerStatus`           | \< 1      |

<div class="note">

Virtual Hub alerts are unique to the Virtual WAN module. The hub-spoke
module does not have equivalent alerts as the hub VNet is not a managed
resource.

</div>

## Best Practices

### Firewall DNS Proxy

DNS Proxy is enabled by default on the firewall policy, as recommended
by [Microsoft’s Well-Architected
Framework](https://learn.microsoft.com/en-us/azure/well-architected/service-guides/azure-firewall#security).

DNS Proxy provides:

- **FQDN filtering** — Required for network rules that filter by FQDN
  (not just IP)

- **DNS query logging** — All DNS queries are logged to Log Analytics

- **Consistent resolution** — All spoke workloads resolve DNS through
  the firewall

To disable:

``` hcl
hubs = {
  uksouth = {
    features = {
      firewall_dns_proxy = false
    }
  }
}
```

### Availability Zones

The module automatically detects availability zone support per region
using the Azure Regions module. Firewalls and bastion hosts are deployed
zone-redundantly when the region supports it.

To override zone configuration:

``` hcl
hubs = {
  uksouth = {
    features = {
      availability_zones = ["1", "2", "3"]
    }
  }
}
```

### Production Configuration

For production workloads, enable monitoring integration, bastion access,
and VPN connectivity:

``` hcl
hubs = {
  uksouth = {
    features = {
      firewall_sku = "Standard"
      bastion      = true
      vpn_gateway  = true
    }
  }
}

management_remote_state = {
  enabled              = true
  storage_account_name = "<storage-account-name>"
}
```

### Virtual WAN Considerations

- Virtual WAN Standard SKU is required for firewall integration and
  ExpressRoute gateways

- Virtual Hub routing is fully managed — no manual route tables or UDRs
  needed

- Sidecar VNet resources (Bastion, DNS Resolver) connect via VNet
  connection to the virtual hub

- DDoS protection applies to sidecar VNets (virtual hubs are managed and
  inherently protected)

## Advanced Configuration

### Flow Logs Storage

Each hub region deploys a storage account for NSG and VNet flow logs.
The storage account name is globally unique, generated using the naming
module’s `name_unique` suffix.

To use an externally created storage account, configure the storage
account resource ID in the hub settings.

### Azure Monitor Private Link Scope (AMPLS)

AMPLS is enabled by default and creates a private endpoint in the
sidecar VNet’s `snet-private-endpoints` subnet. This secures
connectivity between monitoring agents and Log Analytics.

Requirements:

- Log Analytics workspace ID (from management remote state or direct
  input)

- `sidecar_virtual_network` feature enabled (default)

To disable AMPLS:

``` hcl
azure_monitor_private_link = {
  enabled = false
}
```

### Custom DNS Servers

Configure custom upstream DNS servers for the firewall DNS proxy:

``` hcl
hubs = {
  uksouth = {
    dns = {
      servers = ["10.0.0.4", "10.0.0.5"]
    }
    features = {
      firewall_dns_proxy = true
    }
  }
}
```

When DNS servers are specified and DNS proxy is enabled, the firewall
forwards DNS queries to the specified servers instead of Azure DNS.

### Network Watcher

Network Watcher is deployed per region when enabled. It provides network
diagnostic capabilities including connection monitor, packet capture,
and flow logs.

## Troubleshooting

### Common Issues

#### AMPLS validation fails

    Error: AMPLS requires log_analytics_workspace_id

**Cause**: Azure Monitor Private Link Scope is enabled (default) but no
Log Analytics workspace ID is available.

**Fix**: Either configure `management_remote_state` or provide the ID
directly. To disable AMPLS:

``` hcl
azure_monitor_private_link = {
  enabled = false
}
```

#### Terraform destroy fails with locked resource groups

**Cause**: Resource groups have `CanNotDelete` locks enabled by default.

**Fix**: Disable locks before destroying:

``` hcl
resource_group_lock_enabled = false
```

#### Sidecar VNet connection fails

**Cause**: The sidecar VNet must be in the same region as the virtual
hub it connects to.

**Fix**: Ensure the sidecar VNet configuration matches the hub region.
The module handles this automatically — check for manual `address_space`
overrides that may conflict.

#### Virtual Hub provisioning timeout

**Cause**: Virtual Hub deployment can take 20-30 minutes. Large
deployments with multiple gateways may take longer.

**Fix**: Increase Terraform timeouts if needed. The AVM module sets
appropriate defaults.

### Testing

Unit tests validate configuration logic without deploying
infrastructure. Tests use mock providers to run offline.

``` bash
terraform test
```

## API Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                         | Version  |
|------------------------------------------------------------------------------|----------|
| <span id="requirement_terraform"></span> [terraform](#requirement_terraform) | ~> 1.12 |
| <span id="requirement_azapi"></span> [azapi](#requirement_azapi)             | ~> 2.0  |
| <span id="requirement_azurerm"></span> [azurerm](#requirement_azurerm)       | ~> 4.0  |
| <span id="requirement_local"></span> [local](#requirement_local)             | ~> 2.5  |
| <span id="requirement_modtm"></span> [modtm](#requirement_modtm)             | ~> 0.3  |
| <span id="requirement_random"></span> [random](#requirement_random)          | ~> 3.8  |

## Providers

| Name                                                                   | Version |
|------------------------------------------------------------------------|---------|
| <span id="provider_azurerm"></span> [azurerm](#provider_azurerm)       | ~> 4.0 |
| <span id="provider_random"></span> [random](#provider_random)          | ~> 3.8 |
| <span id="provider_terraform"></span> [terraform](#provider_terraform) | n/a     |

## Modules

| Name                                                                                                   | Source                                             | Version |
|--------------------------------------------------------------------------------------------------------|----------------------------------------------------|---------|
| <span id="module_azure_regions"></span> [azure_regions](#module_azure_regions)                         | Azure/avm-utl-regions/azurerm                      | 0.9.3   |
| <span id="module_flow_logs_storage"></span> [flow_logs_storage](#module_flow_logs_storage)             | Azure/avm-res-storage-storageaccount/azurerm       | 0.6.7   |
| <span id="module_naming"></span> [naming](#module_naming)                                              | Azure/naming/azurerm                               | 0.4.3   |
| <span id="module_nsg_private_endpoints"></span> [nsg_private_endpoints](#module_nsg_private_endpoints) | Azure/avm-res-network-networksecuritygroup/azurerm | 0.5.1   |
| <span id="module_resource_groups"></span> [resource_groups](#module_resource_groups)                   | Azure/avm-res-resources-resourcegroup/azurerm      | 0.2.1   |
| <span id="module_virtual_wan"></span> [virtual_wan](#module_virtual_wan)                               | Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm | 0.13.5  |

## Resources

| Name                                                                                                                                                                                             | Type        |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [azurerm_monitor_diagnostic_setting.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting)                                         | resource    |
| [azurerm_monitor_diagnostic_setting.expressroute_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting)                            | resource    |
| [azurerm_monitor_diagnostic_setting.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting)                                        | resource    |
| [azurerm_monitor_diagnostic_setting.vpn_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting)                                     | resource    |
| [azurerm_monitor_metric_alert.expressroute_bits_received](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                  | resource    |
| [azurerm_monitor_metric_alert.expressroute_cpu](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                            | resource    |
| [azurerm_monitor_metric_alert.firewall_health](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                             | resource    |
| [azurerm_monitor_metric_alert.firewall_snat_exhaustion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                    | resource    |
| [azurerm_monitor_metric_alert.firewall_throughput](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                         | resource    |
| [azurerm_monitor_metric_alert.virtual_hub_bgp_peer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                        | resource    |
| [azurerm_monitor_metric_alert.virtual_hub_routing_capacity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                | resource    |
| [azurerm_monitor_metric_alert.vpn_bgp_peer_status](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                         | resource    |
| [azurerm_monitor_metric_alert.vpn_tunnel_bandwidth](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                        | resource    |
| [azurerm_monitor_private_link_scope.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scope)                                            | resource    |
| [azurerm_monitor_private_link_scoped_service.log_analytics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scoped_service)                 | resource    |
| [azurerm_network_watcher.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher)                                                                  | resource    |
| [azurerm_network_watcher_flow_log.sidecar_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log)                                        | resource    |
| [azurerm_private_endpoint.ampls](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint)                                                               | resource    |
| [azurerm_storage_management_policy.flow_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_management_policy)                                         | resource    |
| [azurerm_subnet_network_security_group_association.private_endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource    |
| [random_string.random_seed](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string)                                                                               | resource    |
| [terraform_data.validate_ampls_requirements](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                                             | resource    |
| [terraform_data.validate_flow_logs_requirements](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                                         | resource    |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config)                                                                | data source |
| [terraform_remote_state.management](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state)                                                           | data source |

## Inputs

<table>
<colgroup>
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Name</th>
<th style="text-align: left;">Description</th>
<th style="text-align: left;">Type</th>
<th style="text-align: left;">Default</th>
<th style="text-align: left;">Required</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p><span id="input_company"></span> <a
href="#input_company">company</a></p></td>
<td style="text-align: left;"><p>Company name used in resource naming.
The first 3 characters are used as a prefix (e.g., 'ensono' becomes
'ens').</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p>n/a</p></td>
<td style="text-align: left;"><p>yes</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_connectivity_subscription_id"></span> <a
href="#input_connectivity_subscription_id">connectivity_subscription_id</a></p></td>
<td style="text-align: left;"><p>Subscription ID for connectivity
resources (virtual WAN, hubs, firewalls).</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p>n/a</p></td>
<td style="text-align: left;"><p>yes</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span id="input_hubs"></span> <a
href="#input_hubs">hubs</a></p></td>
<td style="text-align: left;"><p>Virtual hub configurations keyed by
Azure region name.</p></td>
<td style="text-align: left;"><pre><code>map(object({
    enabled       = optional(bool, true)
    address_space = optional(string)
&#10;    features = optional(object({
      firewall                   = optional(bool, true)
      firewall_sku               = optional(string, &quot;Standard&quot;)
      firewall_dns_proxy         = optional(bool, true)
      firewall_threat_intel_mode = optional(string, &quot;Alert&quot;)
      bastion                    = optional(bool, false)
      vpn_gateway                = optional(bool, false)
      expressroute_gateway       = optional(bool, false)
      private_dns_zones          = optional(bool, true)
      private_dns_resolver       = optional(bool, false)
      sidecar_virtual_network    = optional(bool, true)
      availability_zones         = optional(list(number))
    }), {})
&#10;    hub = optional(object({
      sku                                    = optional(string)
      hub_routing_preference                 = optional(string, &quot;ExpressRoute&quot;)
      virtual_router_auto_scale_min_capacity = optional(number, 2)
    }), {})
&#10;    sidecar_subnets = optional(object({
      bastion_address_prefix              = optional(string)
      gateway_address_prefix              = optional(string)
      private_dns_resolver_address_prefix = optional(string)
      private_endpoints_address_prefix    = optional(string)
    }), {})
&#10;    dns = optional(object({
      auto_registration_zone_name = optional(string)
      servers                     = optional(list(string))
    }), {})
&#10;    name_overrides = optional(object({
      resource_group          = optional(string)
      virtual_hub             = optional(string)
      sidecar_virtual_network = optional(string)
      firewall                = optional(string)
      firewall_policy         = optional(string)
      bastion                 = optional(string)
      vpn_gateway             = optional(string)
      expressroute_gateway    = optional(string)
      private_dns_resolver    = optional(string)
    }), {})
&#10;    tags = optional(map(string), {})
  }))</code></pre></td>
<td style="text-align: left;"><p>n/a</p></td>
<td style="text-align: left;"><p>yes</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_azure_monitor_private_link"></span> <a
href="#input_azure_monitor_private_link">azure_monitor_private_link</a></p></td>
<td style="text-align: left;"><p>Azure Monitor Private Link Scope
configuration for private connectivity to Log Analytics.</p></td>
<td style="text-align: left;"><pre><code>object({
    enabled                    = optional(bool, true)
    log_analytics_workspace_id = optional(string)
    ingestion_access_mode      = optional(string, &quot;PrivateOnly&quot;)
    query_access_mode          = optional(string, &quot;PrivateOnly&quot;)
    name                       = optional(string)
  })</code></pre></td>
<td style="text-align: left;"><p><code>{}</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_ddos_protection_plan"></span> <a
href="#input_ddos_protection_plan">ddos_protection_plan</a></p></td>
<td style="text-align: left;"><p>DDoS Protection Plan configuration.
Disabled by default due to significant cost (~£2,200/month).</p>
<ul>
<li><p><code>enabled</code> - (Optional) Enable DDoS Protection Plan.
Default: <code>false</code>.</p></li>
</ul></td>
<td style="text-align: left;"><pre><code>object({
    enabled = optional(bool, false)
  })</code></pre></td>
<td style="text-align: left;"><p><code>{}</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_enable_avm_telemetry"></span> <a
href="#input_enable_avm_telemetry">enable_avm_telemetry</a></p></td>
<td style="text-align: left;"><p>Enable telemetry collection for Azure
Verified Modules. See <a
href="https://aka.ms/avm/telemetryinfo">https://aka.ms/avm/telemetryinfo</a>.</p></td>
<td style="text-align: left;"><p><code>bool</code></p></td>
<td style="text-align: left;"><p><code>false</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span id="input_flow_logs"></span> <a
href="#input_flow_logs">flow_logs</a></p></td>
<td style="text-align: left;"><p>Flow logs configuration for network
traffic analysis on sidecar VNets. Disabled by default.</p>
<pre><code>Note: Virtual WAN hub traffic is managed by Microsoft and not visible via VNet flow logs.
Flow logs for Virtual WAN capture traffic in the sidecar virtual networks (Bastion, DNS Resolver, etc.).</code></pre>
<pre><code>Per Microsoft documentation, the storage account MUST be in the same region as the VNet.
This module creates a storage account per hub region to ensure compliance.</code></pre>
<pre><code>When enabled, creates:
- Storage account per hub region
- VNet flow logs for each sidecar virtual network</code></pre>
<pre><code>Storage options:
- create: Set to true (default) to create storage accounts
- external_storage_account_id: If create=false, provide an existing storage account ID
  (must be in same region as sidecar VNet)</code></pre>
<pre><code>Optional:
- Traffic Analytics (requires Log Analytics workspace via management_remote_state)</code></pre>
<pre><code>Cost considerations:
- Storage: ~£0.02/GB stored (~£15-50/month depending on traffic volume)
- Traffic Analytics: Additional Log Analytics ingestion costs</code></pre>
<pre><code>Note: Retention defaults to 90 days to meet security compliance requirements (CKV_AZURE_12).</code></pre></td>
<td style="text-align: left;"><pre><code>object({
    enabled                   = optional(bool, false)
    retention_days            = optional(number, 90)
    traffic_analytics_enabled = optional(bool, false)
    storage = optional(object({
      create                      = optional(bool, true)
      external_storage_account_id = optional(string, null)
      access_tier                 = optional(string, &quot;Hot&quot;)
      account_kind                = optional(string, &quot;StorageV2&quot;)
      account_replication_type    = optional(string, &quot;GRS&quot;)
      account_tier                = optional(string, &quot;Standard&quot;) # Premium not supported
      min_tls_version             = optional(string, &quot;TLS1_2&quot;)
      public_network_access       = optional(bool, false)
      shared_access_key_enabled   = optional(bool, true)
      retention_days              = optional(number, 30) # Blob lifecycle
      network_rules = optional(object({
        ip_rules                   = optional(list(string), [])
        virtual_network_subnet_ids = optional(list(string), [])
      }), {})
    }), {})
  })</code></pre></td>
<td style="text-align: left;"><p><code>{}</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_hub_network_address_prefix"></span> <a
href="#input_hub_network_address_prefix">hub_network_address_prefix</a></p></td>
<td style="text-align: left;"><p>Base address space for hub networks.
Each hub receives a /16.</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p><code>"10.0.0.0/8"</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_management_remote_state"></span> <a
href="#input_management_remote_state">management_remote_state</a></p></td>
<td style="text-align: left;"><p>Configuration for reading management
landing zone state to get Log Analytics workspace ID.</p>
<ul>
<li><p><code>enabled</code> - (Optional) Enable remote state lookup.
Default: <code>true</code>.</p></li>
<li><p><code>backend</code> - (Optional) Backend type. Default:
<code>azurerm</code>.</p></li>
<li><p><code>storage_account_name</code> - (Required when enabled)
Storage account name for state.</p></li>
<li><p><code>container_name</code> - (Optional) Blob container name.
Default: <code>tfstate</code>.</p></li>
<li><p><code>key</code> - (Optional) State file key. Default:
<code>management.tfstate</code>.</p></li>
<li><p><code>workspace</code> - (Optional) Terraform workspace. Default:
current workspace.</p></li>
<li><p><code>use_azuread_auth</code> - (Optional) Use Entra ID auth.
Default: <code>true</code>.</p></li>
</ul></td>
<td style="text-align: left;"><pre><code>object({
    enabled              = optional(bool, true)
    backend              = optional(string, &quot;azurerm&quot;)
    workspace            = optional(string)
    storage_account_name = optional(string)
    container_name       = optional(string, &quot;tfstate&quot;)
    key                  = optional(string, &quot;management.tfstate&quot;)
    use_azuread_auth     = optional(bool, true)
  })</code></pre></td>
<td style="text-align: left;"><p><code>{}</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_network_watcher"></span> <a
href="#input_network_watcher">network_watcher</a></p></td>
<td style="text-align: left;"><p>Network Watcher configuration. Network
Watcher is free and provides network diagnostics capabilities.</p></td>
<td style="text-align: left;"><pre><code>object({
    enabled = optional(bool, true)
  })</code></pre></td>
<td style="text-align: left;"><p><code>{}</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_private_endpoints_nsg"></span> <a
href="#input_private_endpoints_nsg">private_endpoints_nsg</a></p></td>
<td style="text-align: left;"><p>Configuration for the Network Security
Group on the private endpoints subnet in the sidecar VNet.</p>
<p>NSG provides: - Centralized access control for private endpoints -
Visibility through NSG flow logs - Compliance auditing capability</p>
<p>Microsoft recommends using NSG on private endpoint subnets to control
and log access. See: <a
href="https://learn.microsoft.com/en-us/azure/architecture/networking/guide/private-link-hub-spoke-network">https://learn.microsoft.com/en-us/azure/architecture/networking/guide/private-link-hub-spoke-network</a></p>
<ul>
<li><p><code>enabled</code> - (Optional) Deploy NSG on private endpoints
subnet. Defaults to <code>true</code>.</p></li>
</ul>
<p>Note: When <code>enabled = true</code>, an NSG with default rules is
created: - AllowVNetInbound (priority 100): Allow traffic from
VirtualNetwork - DenyInternetInbound (priority 4096): Deny traffic from
Internet</p>
<p>The NSG is only deployed when: - <code>enabled = true</code> -
Sidecar VNet is enabled for the hub - AMPLS is enabled (which creates
the private endpoints subnet)</p></td>
<td style="text-align: left;"><pre><code>object({
    enabled = optional(bool, true)
  })</code></pre></td>
<td style="text-align: left;"><pre><code>{
  &quot;enabled&quot;: true
}</code></pre></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_region_geography"></span> <a
href="#input_region_geography">region_geography</a></p></td>
<td style="text-align: left;"><p>Filter available regions by geography.
Common values: 'United Kingdom', 'Europe', 'United States', 'Asia
Pacific'. Set to null for all geographies.</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p><code>null</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_region_recommended_filter"></span> <a
href="#input_region_recommended_filter">region_recommended_filter</a></p></td>
<td style="text-align: left;"><p>Filter by Microsoft-recommended
regions. Set to true for recommended only, false for non-recommended
only, or null (default) for all regions.</p></td>
<td style="text-align: left;"><p><code>bool</code></p></td>
<td style="text-align: left;"><p><code>null</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_resource_group_lock_enabled"></span> <a
href="#input_resource_group_lock_enabled">resource_group_lock_enabled</a></p></td>
<td style="text-align: left;"><p>Enable CanNotDelete locks on all
resource groups. Set to false before running terraform destroy.</p></td>
<td style="text-align: left;"><p><code>bool</code></p></td>
<td style="text-align: left;"><p><code>true</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span id="input_tags"></span> <a
href="#input_tags">tags</a></p></td>
<td style="text-align: left;"><p>Tags applied to all resources.</p></td>
<td style="text-align: left;"><p><code>map(string)</code></p></td>
<td style="text-align: left;"><p><code>{}</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
</tbody>
</table>

## Outputs

| Name                                                                                                                                                   | Description                                                                         |
|--------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| <span id="output_ampls_private_endpoint_ids"></span> [ampls_private_endpoint_ids](#output_ampls_private_endpoint_ids)                                  | AMPLS private endpoint IDs, keyed by region.                                        |
| <span id="output_azure_monitor_private_link_scope_id"></span> [azure_monitor_private_link_scope_id](#output_azure_monitor_private_link_scope_id)       | Azure Monitor Private Link Scope resource ID.                                       |
| <span id="output_azure_monitor_private_link_scope_name"></span> [azure_monitor_private_link_scope_name](#output_azure_monitor_private_link_scope_name) | Azure Monitor Private Link Scope name.                                              |
| <span id="output_bastion_diagnostic_setting_ids"></span> [bastion_diagnostic_setting_ids](#output_bastion_diagnostic_setting_ids)                      | Diagnostic setting IDs for Bastion hosts, keyed by region.                          |
| <span id="output_bastion_host_dns_names"></span> [bastion_host_dns_names](#output_bastion_host_dns_names)                                              | Bastion DNS names, keyed by region.                                                 |
| <span id="output_bastion_host_public_ip_addresses"></span> [bastion_host_public_ip_addresses](#output_bastion_host_public_ip_addresses)                | Bastion public IPs, keyed by region.                                                |
| <span id="output_bastion_host_resource_ids"></span> [bastion_host_resource_ids](#output_bastion_host_resource_ids)                                     | Bastion host resource IDs, keyed by region.                                         |
| <span id="output_dns_server_ip_addresses"></span> [dns_server_ip_addresses](#output_dns_server_ip_addresses)                                           | DNS server IPs (firewall private IP when DNS Proxy enabled, or DNS Resolver IPs).   |
| <span id="output_express_route_gateway_resource_ids"></span> [express_route_gateway_resource_ids](#output_express_route_gateway_resource_ids)          | ExpressRoute gateway resource IDs, keyed by region.                                 |
| <span id="output_firewall_alert_ids"></span> [firewall_alert_ids](#output_firewall_alert_ids)                                                          | Firewall metric alert IDs, keyed by region and alert type.                          |
| <span id="output_firewall_diagnostic_setting_ids"></span> [firewall_diagnostic_setting_ids](#output_firewall_diagnostic_setting_ids)                   | Diagnostic setting IDs for firewall.                                                |
| <span id="output_firewall_policy_resource_ids"></span> [firewall_policy_resource_ids](#output_firewall_policy_resource_ids)                            | Azure Firewall Policy resource IDs, keyed by region.                                |
| <span id="output_firewall_private_ip_addresses"></span> [firewall_private_ip_addresses](#output_firewall_private_ip_addresses)                         | Firewall private IPs for routing, keyed by region.                                  |
| <span id="output_firewall_public_ip_addresses"></span> [firewall_public_ip_addresses](#output_firewall_public_ip_addresses)                            | Firewall public IPs, keyed by region.                                               |
| <span id="output_firewall_resource_ids"></span> [firewall_resource_ids](#output_firewall_resource_ids)                                                 | Azure Firewall resource IDs, keyed by region.                                       |
| <span id="output_firewall_resource_names"></span> [firewall_resource_names](#output_firewall_resource_names)                                           | Azure Firewall names, keyed by region.                                              |
| <span id="output_flow_log_ids"></span> [flow_log_ids](#output_flow_log_ids)                                                                            | VNet flow log IDs for sidecar virtual networks, keyed by region.                    |
| <span id="output_flow_logs_storage_account_ids"></span> [flow_logs_storage_account_ids](#output_flow_logs_storage_account_ids)                         | Flow logs storage account IDs, keyed by region.                                     |
| <span id="output_flow_logs_storage_account_names"></span> [flow_logs_storage_account_names](#output_flow_logs_storage_account_names)                   | Flow logs storage account names, keyed by region.                                   |
| <span id="output_gateway_alert_ids"></span> [gateway_alert_ids](#output_gateway_alert_ids)                                                             | Gateway metric alert IDs, keyed by region and alert type.                           |
| <span id="output_gateway_diagnostic_setting_ids"></span> [gateway_diagnostic_setting_ids](#output_gateway_diagnostic_setting_ids)                      | Diagnostic setting IDs for VPN and ExpressRoute gateways, keyed by type and region. |
| <span id="output_hub_address_spaces"></span> [hub_address_spaces](#output_hub_address_spaces)                                                          | Address space per hub.                                                              |
| <span id="output_hub_regions"></span> [hub_regions](#output_hub_regions)                                                                               | Regions where virtual hubs are deployed.                                            |
| <span id="output_network_watcher_ids"></span> [network_watcher_ids](#output_network_watcher_ids)                                                       | Network Watcher resource IDs, keyed by region.                                      |
| <span id="output_primary_hub_region"></span> [primary_hub_region](#output_primary_hub_region)                                                          | Primary hub region (first alphabetically).                                          |
| <span id="output_private_dns_resolver_resource_ids"></span> [private_dns_resolver_resource_ids](#output_private_dns_resolver_resource_ids)             | Private DNS resolver resource IDs, keyed by region.                                 |
| <span id="output_private_endpoints_nsg_ids"></span> [private_endpoints_nsg_ids](#output_private_endpoints_nsg_ids)                                     | Private endpoints NSG resource IDs, keyed by region.                                |
| <span id="output_resource_group_ids"></span> [resource_group_ids](#output_resource_group_ids)                                                          | Resource group IDs.                                                                 |
| <span id="output_resource_group_names"></span> [resource_group_names](#output_resource_group_names)                                                    | Resource group names.                                                               |
| <span id="output_sidecar_virtual_network_resource_ids"></span> [sidecar_virtual_network_resource_ids](#output_sidecar_virtual_network_resource_ids)    | Sidecar virtual network resource IDs, keyed by region.                              |
| <span id="output_virtual_hub_alert_ids"></span> [virtual_hub_alert_ids](#output_virtual_hub_alert_ids)                                                 | Virtual Hub metric alert IDs, keyed by region and alert type.                       |
| <span id="output_virtual_hub_resource_ids"></span> [virtual_hub_resource_ids](#output_virtual_hub_resource_ids)                                        | The resource IDs of the virtual hubs, keyed by region.                              |
| <span id="output_virtual_hub_resource_names"></span> [virtual_hub_resource_names](#output_virtual_hub_resource_names)                                  | The names of the virtual hubs, keyed by region.                                     |
| <span id="output_virtual_wan_name"></span> [virtual_wan_name](#output_virtual_wan_name)                                                                | The name of the virtual WAN.                                                        |
| <span id="output_virtual_wan_resource_id"></span> [virtual_wan_resource_id](#output_virtual_wan_resource_id)                                           | The resource ID of the virtual WAN.                                                 |

<!-- END_TF_DOCS -->

## Support

For issues, questions, or contributions related to this module, please
contact the Ensono Stacks team.

## License

Copyright (c) 2026 Ensono

This project is licensed under the MIT License.
