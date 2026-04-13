# Stacks Azure Platform Landing Zone - Connectivity Hub and Spoke

## Overview

The **Stacks Azure Platform Landing Zone Connectivity Hub-Spoke** module
deploys a hub-spoke network topology using the below Azure Verified
Modules:

[Hub and Spoke
Networking](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm/latest)

It supports single or multi-region deployments with automatic IP
allocation and CAF-compliant naming.

Hub-spoke provides a self-managed hub VNet with Azure Firewall, route
tables, and mesh peering between hubs. Spoke VNets peer directly to the
hub and use route tables to force traffic through the firewall.

``` mermaid
flowchart TB
    subgraph Internet
        PIP["Public IPs"]
    end

    subgraph Hub["Hub VNet (per region)"]
        direction TB

        subgraph FW["Azure Firewall"]
            FWSubnet["AzureFirewallSubnet /26"]
            FWMgmt["AzureFirewallManagementSubnet /26"]
        end

        subgraph Gateway["Gateways (optional)"]
            GWSubnet["GatewaySubnet /27"]
            VPN["VPN Gateway"]
            ER["ExpressRoute"]
        end

        subgraph DNS["Private DNS"]
            Resolver["DNS Resolver /28"]
            Zones["Private DNS Zones"]
        end

        subgraph Services["Platform Services"]
            Bastion["AzureBastionSubnet /26"]
            PE["snet-private-endpoints /26"]
            AMPLS["AMPLS Private Endpoint"]
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
    Spokes -.-> |"VNet Peering"| Hub
    Gateway --> |"Hybrid"| OnPrem["On-Premises"]
    DNS --> Spokes
    AMPLS --> LogAnalytics
    PE --> Zones
```

### Module Chain

    resource_groups → hub_and_spoke_vnet

1.  **resource_groups** — Deploys resource groups per hub region using
    `for_each` from configuration

2.  **hub_and_spoke_vnet** — Deploys hub virtual networks, firewall,
    bastion, DNS, and gateways using
    [avm-ptn-alz-connectivity-hub-and-spoke-vnet](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm/latest)

### Prerequisites

- Terraform \>= 1.12

- AzureRM provider \>= 4.0

- AzAPI provider \>= 2.0

- Azure subscription for connectivity resources

- Management Landing Zone deployed (for Log Analytics integration)

## Features

| Feature                    | Default | Description                                                   |
|----------------------------|---------|---------------------------------------------------------------|
| Hub Virtual Networks       | ✅      | With mesh peering for multi-region                            |
| Azure Firewall             | ✅      | Standard SKU (configurable: Basic/Standard/Premium)           |
| Firewall DNS Proxy         | ✅      | Enables FQDN filtering and DNS query logging                  |
| Firewall Health Alerts     | ✅      | Alerts for health, SNAT exhaustion, and throughput            |
| Firewall Diagnostics       | ✅      | All log categories sent to Log Analytics                      |
| Network Watcher            | ✅      | Free network diagnostics (Connection Monitor, Packet Capture) |
| Private Endpoints NSG      | ✅      | NSG for visibility and access control                         |
| Private DNS Zones          | ✅      | For Azure Private Link services                               |
| Private DNS Resolver       | ❌      | For hybrid DNS resolution                                     |
| Azure Monitor Private Link | ✅      | Private connectivity to Log Analytics                         |
| Flow Logs                  | ❌      | VNet flow logs with per-region storage (storage costs apply)  |
| Azure Bastion              | ❌      | Secure VM access                                              |
| VPN Gateway                | ❌      | Site-to-Site/Point-to-Site VPN                                |
| VPN Gateway Diagnostics    | ✅      | Tunnel, route, and IKE diagnostics (when gateway enabled)     |
| ExpressRoute Gateway       | ❌      | ExpressRoute connectivity                                     |
| ExpressRoute Diagnostics   | ✅      | Gateway and route diagnostics (when gateway enabled)          |
| DDoS Protection Plan       | ❌      | Shared across all hubs                                        |

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

## Architecture

### IP Address Layout

Default subnet layout within each hub’s `/22`:

| Subnet                        | Size | Default Range (first hub) | Purpose                             |
|-------------------------------|------|---------------------------|-------------------------------------|
| AzureFirewallSubnet           | /26  | 10.0.0.0/26               | Azure Firewall (required name)      |
| AzureBastionSubnet            | /26  | 10.0.0.64/26              | Azure Bastion (required name)       |
| snet-private-endpoints        | /26  | 10.0.0.128/26             | Platform private endpoints          |
| AzureFirewallManagementSubnet | /26  | 10.0.0.192/26             | Firewall management (required name) |
| GatewaySubnet                 | /27  | 10.0.1.0/27               | VPN/ExpressRoute (required name)    |
| PrivateDnsResolverSubnet      | /28  | 10.0.1.32/28              | Private DNS Resolver                |

### IP Allocation Algorithm

Hubs are sorted alphabetically by region name to ensure deterministic IP
allocation. Each hub receives a `/16` block, with the VNet using the
first `/22`:

    Base: 10.0.0.0/8 (configurable via hub_network_address_prefix)

    uksouth: 10.0.0.0/16 → VNet: 10.0.0.0/22
    ukwest:  10.1.0.0/16 → VNet: 10.1.0.0/22

Each `/22` provides 1024 IPs, divided into:

    ┌─────────────────────────────────────────────────────────────┐
    │                    Hub Address Space /22                     │
    ├─────────────────────────────────────────────────────────────┤
    │  First /24 (256 IPs)           │  Second /24 (256 IPs)      │
    │  ┌─────────┬─────────┐         │  ┌─────────┬─────────┐     │
    │  │ /26     │ /26     │         │  │ /27     │ /28 /28 │     │
    │  │ FW      │ Bastion │         │  │ Gateway │ DNS Rsv │     │
    │  ├─────────┼─────────┤         │  └─────────┴─────────┘     │
    │  │ /26     │ /26     │         │                            │
    │  │ PE      │ FW Mgmt │         │  Remaining: custom subnets │
    │  └─────────┴─────────┘         │                            │
    └─────────────────────────────────────────────────────────────┘

<div class="note">

The module supports up to 256 regions using the `10.0.0.0/8` address
space. Regions are sorted alphabetically for consistent IP allocation
across deployments.

</div>

### Mesh Peering

When multiple hubs are deployed, VNet peering is automatically
configured between all hubs, providing full mesh connectivity.

## Configuration Examples

### Multi-Region Deployment

``` hcl
hubs = {
  uksouth = {}
  ukwest  = {}
}
```

IP addresses are calculated automatically (sorted alphabetically). Each
hub receives a `/16` block, with the VNet using the first `/22`:

- uksouth: `10.0.0.0/22` (from `10.0.0.0/16`)

- ukwest: `10.1.0.0/22` (from `10.1.0.0/16`)

Mesh VNet peering is configured automatically between all hubs.

### Cost Optimisation for Non-Production

Use Firewall `Basic` SKU for dev/test environments (~£540/month savings
per hub):

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

Firewall `Basic` SKU has reduced throughput (250 Mbps) and fewer
features. Not recommended for production.

</div>

### Enable Optional Features

``` hcl
hubs = {
  uksouth = {
    features = {
      bastion              = true
      vpn_gateway          = true
      expressroute_gateway = true
    }
  }
}
```

### Custom IP Addressing

``` hcl
hubs = {
  uksouth = {
    address_space = "172.16.0.0/16"
    subnets = {
      firewall_address_prefix             = "172.16.0.0/26"
      bastion_address_prefix              = "172.16.0.64/26"
      private_endpoints_address_prefix    = "172.16.0.128/26"
      firewall_management_address_prefix  = "172.16.0.192/26"
      gateway_address_prefix              = "172.16.1.0/27"
      private_dns_resolver_address_prefix = "172.16.1.32/28"
    }
  }
}
```

### Custom Resource Names

``` hcl
hubs = {
  uksouth = {
    name_overrides = {
      resource_group  = "rg-network-hub-prod"
      virtual_network = "vnet-hub-prod"
      firewall        = "fw-hub-prod"
    }
  }
}
```

### Custom DNS Zone

``` hcl
hubs = {
  uksouth = {
    dns = {
      auto_registration_zone_name = "uksouth.corp.ensono.com"
    }
  }
}
```

### Disable a Hub Temporarily

``` hcl
hubs = {
  uksouth = {}
  ukwest  = { enabled = false }
}
```

### Custom Subnets in Hub

``` hcl
hubs = {
  uksouth = {
    custom_subnets = {
      management = {
        name             = "snet-management"
        address_prefixes = ["10.0.2.0/24"]
      }
    }
  }
}
```

### DDoS Protection Plan

DDoS Protection Plan is **disabled by default** due to significant cost
(~£2,200/month flat fee). The plan is shared across all VNets in the
subscription.

``` hcl
ddos_protection_plan = {
  enabled = true
}
```

<div class="note">

DDoS Protection Plan provides L3/L4 protection, telemetry, and rapid
response support. Consider enabling for production workloads with
public-facing endpoints.

</div>

### Cost Estimation

Estimated monthly costs per hub (UK South, January 2025):

| Resource                    | Default | Monthly Cost (GBP) | Notes                      |
|-----------------------------|---------|--------------------|----------------------------|
| Azure Firewall Standard     | ✅      | ~£720              | 3 AZ deployment            |
| Azure Firewall Basic        | ❌      | ~£180              | Dev/test alternative       |
| VPN Gateway (VpnGw1AZ)      | ❌      | ~£140              | Active-active              |
| ExpressRoute Gateway        | ❌      | ~£140              | ErGw1AZ SKU                |
| Azure Bastion Standard      | ❌      | ~£140              | 2 scale units              |
| DDoS Protection Plan        | ❌      | ~£2,200            | Shared across subscription |
| Log Analytics               | \-      | Variable           | ~£2/GB/month ingestion     |
| **Minimum (Firewall only)** |         | **~£720**          |                            |
| **Full Production**         |         | **~£1,140**        | Firewall + VPN + Bastion   |

<div class="tip">

For multi-region, multiply per-hub costs. DDoS Protection Plan is shared
across all regions.

</div>

## Resource Naming

Resources follow [Cloud Adoption Framework
(CAF)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
naming conventions using the [Azure
Naming](https://registry.terraform.io/modules/Azure/naming/azurerm/latest)
module. Names can be overridden per hub using `name_overrides`.

### Generated Names

With `company = "ensono"`, region `uksouth` (geo_code `uks`), and
workspace `prd`:

| Resource                    | Generated Name                  | Name Override Key      |
|-----------------------------|---------------------------------|------------------------|
| Resource Group              | `rg-ens-uks-prd-hub-001`        | `resource_group`       |
| Virtual Network             | `vnet-ens-uks-prd-hub-001`      | `virtual_network`      |
| Firewall                    | `afw-ens-uks-prd-hub-001`       | `firewall`             |
| Firewall Policy             | `afwp-ens-uks-prd-hub-001`      | `firewall_policy`      |
| Route Table (firewall)      | `rt-ens-uks-prd-hub-fw-001`     | `route_table_firewall` |
| Route Table (user)          | `rt-ens-uks-prd-hub-std-001`    | `route_table_user`     |
| Bastion Host                | `bas-ens-uks-prd-hub-001`       | `bastion`              |
| VPN Gateway                 | `vgw-ens-uks-prd-hub-vpn-001`   | `vpn_gateway`          |
| ExpressRoute Gateway        | `vgw-ens-uks-prd-hub-er-001`    | `expressroute_gateway` |
| DNS Resolver                | `dnspr-ens-uks-prd-hub-dns-001` | `private_dns_resolver` |
| Storage Account (flow logs) | `st<unique>ensukshubfl001`      | \-                     |

### Naming Pattern

Names follow the pattern:
`{caf_prefix}-{company_3}-{geo_code}-{workspace}-{component}-{instance}`

The module uses `substr(var.company, 0, 3)` to limit the company prefix
length and the region’s `geo_code` (e.g., `uks` for UK South), ensuring
resource names stay within Azure limits.

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

- Deploys metric alerts for firewall and gateways

- Configures Azure Monitor Private Link Scope (AMPLS)

### Spoke Integration

The module provides outputs for spoke landing zones to integrate with
hub infrastructure.

#### Route Traffic Through Firewall

``` hcl
data "terraform_remote_state" "connectivity" {
  backend   = "azurerm"
  workspace = terraform.workspace

  config = {
    storage_account_name = "<storage-account>"
    container_name       = "tfstate"
    key                  = "connectivity.tfstate"
    use_azuread_auth     = true
  }
}

resource "azurerm_subnet_route_table_association" "spoke" {
  subnet_id      = azurerm_subnet.workload.id
  route_table_id = data.terraform_remote_state.connectivity.outputs.route_table_user_subnets_ids["uksouth"]
}
```

#### Link Private DNS Zones

``` hcl
resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  for_each = data.terraform_remote_state.connectivity.outputs.private_dns_zone_resource_ids["uksouth"]

  name                  = "link-spoke-${var.spoke_name}"
  resource_group_name   = "rg-dns-uksouth"
  private_dns_zone_name = split("/", each.value)[8]
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
}
```

#### VNet Peering to Hub

``` hcl
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-to-hub"
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = data.terraform_remote_state.connectivity.outputs.virtual_network_resource_ids["uksouth"]
  allow_forwarded_traffic   = true
  use_remote_gateways       = true  # If VPN/ER gateway exists
}
```

#### AMPLS Integration

Application landing zones can add their own scoped services using the
AMPLS outputs:

``` hcl
resource "azurerm_monitor_private_link_scoped_service" "app_insights" {
  name                = "appinsights-myapp"
  resource_group_name = data.terraform_remote_state.connectivity.outputs.ampls_resource_group_name
  scope_name          = data.terraform_remote_state.connectivity.outputs.ampls_name
  linked_resource_id  = azurerm_application_insights.this.id
}
```

### Available Outputs for Spoke Integration

| Output                                     | Description                                   |
|--------------------------------------------|-----------------------------------------------|
| `virtual_network_resource_ids`             | Hub VNet IDs for peering                      |
| `firewall_private_ip_addresses`            | Firewall IPs for custom routes                |
| `route_table_user_subnets_ids`             | Route tables forcing traffic through firewall |
| `private_dns_zone_resource_ids`            | DNS zones for VNet linking                    |
| `dns_server_ip_addresses`                  | DNS Resolver IPs for spoke DNS settings       |
| `ampls_name` / `ampls_resource_group_name` | For adding Application Insights to AMPLS      |

## Metric Alerts

Metric alerts are deployed when a Log Analytics workspace ID is
available (via management remote state or direct configuration). Alerts
target firewalls and gateways.

### Firewall Alerts

| Alert                | Severity     | Metric                | Condition           |
|----------------------|--------------|-----------------------|---------------------|
| Health Degradation   | 1 (Critical) | `FirewallHealth`      | Average \< 100%     |
| SNAT Port Exhaustion | 2 (Warning)  | `SNATPortUtilization` | Average \> 80%      |
| High Throughput      | 2 (Warning)  | `Throughput`          | Average \> 2.5 Gbps |

### VPN Gateway Alerts

Deployed only when `vpn_gateway = true`:

| Alert                | Severity    | Metric               | Condition       |
|----------------------|-------------|----------------------|-----------------|
| Tunnel Egress Drop   | 2 (Warning) | `TunnelEgressBytes`  | Total \< 1 byte |
| P2S Connection Count | 2 (Warning) | `P2SConnectionCount` | Average \> 100  |

### ExpressRoute Gateway Alerts

Deployed only when `expressroute_gateway = true`:

| Alert           | Severity    | Metric                              | Condition      |
|-----------------|-------------|-------------------------------------|----------------|
| Traffic Drop    | 2 (Warning) | `ExpressRouteGatewayBitsPerSecond`  | Average \< 1   |
| CPU Utilisation | 2 (Warning) | `ExpressRouteGatewayCpuUtilization` | Average \> 80% |

All alerts are keyed by region and tagged with `var.tags`. Alert
thresholds can be adjusted by modifying the alert resources directly.

## Best Practices

### Firewall DNS Proxy

DNS Proxy is **enabled by default** on the firewall policy, as
recommended by [Microsoft’s Well-Architected
Framework](https://learn.microsoft.com/en-us/azure/well-architected/service-guides/azure-firewall#security).

DNS Proxy provides:

- **FQDN filtering** — Required for network rules that filter by FQDN
  (not just IP)

- **DNS query logging** — All DNS queries are logged to Log Analytics

- **Consistent resolution** — All spoke workloads resolve DNS through
  the firewall

When enabled, spoke VNets should configure their DNS servers to point to
the firewall private IP (available via `firewall_private_ip_addresses`
output).

To disable DNS Proxy:

``` hcl
hubs = {
  uksouth = {
    features = {
      firewall_dns_proxy = false
    }
  }
}
```

<div class="tip">

DNS Proxy is essential for FQDN-based network rules. Without it,
firewall network rules can only filter by IP address.

</div>

### Private Endpoints NSG

A Network Security Group is deployed on the private endpoints subnet by
default, as recommended by [Microsoft’s hub-spoke architecture
guidance](https://learn.microsoft.com/en-us/azure/architecture/networking/guide/private-link-hub-spoke-network).

The NSG provides:

- **Visibility** — NSG flow logs for auditing and compliance

- **Access control** — Centralised place to control traffic to private
  endpoints

- **Defence in depth** — Additional security layer alongside Azure
  Firewall

Default rules:

| Rule                | Priority | Direction | Action | Source         | Destination    |
|---------------------|----------|-----------|--------|----------------|----------------|
| AllowVNetInbound    | 100      | Inbound   | Allow  | VirtualNetwork | VirtualNetwork |
| DenyInternetInbound | 4096     | Inbound   | Deny   | Internet       | Any            |

<div class="note">

When using Azure Firewall, the NSG provides additional visibility and
logging. Traffic is already controlled by the firewall, but the NSG
enables NSG flow logs for the private endpoints subnet.

</div>

### Availability Zones

Availability zones are **auto-detected** based on region support.
Regions like `uksouth` that support zones will automatically deploy
zone-redundant resources (99.99% SLA), while regions like `ukwest`
without zone support will deploy without zones (99.95% SLA).

To explicitly override (e.g., disable zones for cost savings in
dev/test):

``` hcl
hubs = {
  uksouth = {
    features = {
      availability_zones = null  # Disable zones even in supported region
    }
  }
}
```

<div class="note">

Zone-redundant deployments incur cross-zone data transfer charges
(~£0.01/GB).

</div>

### Production Configuration

For production workloads, enable flow logs for network visibility:

``` hcl
hubs = {
  uksouth = {
    features = {
      firewall_sku = "Standard"
    }
  }
}

flow_logs = {
  enabled        = true
  retention_days = 90
  storage = {
    create = true
  }
  traffic_analytics_enabled = true
}

management_remote_state = {
  storage_account_name = "<storage-account-name>"
}
```

<div class="note">

Traffic Analytics requires `management_remote_state` to be enabled to
obtain the Log Analytics workspace GUID.

</div>

### Hub-Spoke Considerations

- Mesh VNet peering is automatically configured when multiple hubs are
  deployed, providing full hub-to-hub connectivity

- Route tables are explicitly managed — user subnet route tables force
  traffic through Azure Firewall

- Private Endpoints NSG is unique to hub-spoke topology, providing
  additional visibility and access control

- DDoS protection applies directly to hub VNets (unlike Virtual WAN
  where hubs are managed infrastructure)

- Spoke VNets must be peered manually to the hub and associated with the
  firewall route table

## Advanced Configuration

### Flow Logs Storage

VNet flow logs require a storage account in the **same region** as the
monitored VNet. This module can create per-region storage accounts
automatically.

#### Create Storage Per Hub Region (Recommended)

``` hcl
flow_logs = {
  enabled = true
  storage = {
    create                   = true
    account_tier             = "Standard"
    account_replication_type = "GRS"   # LRS for dev/test
    retention_days           = 30      # Blob lifecycle retention
    public_network_access    = false
  }
  retention_days            = 90     # Flow logs retention (min 90 for compliance)
  traffic_analytics_enabled = true
}
```

#### Use External Storage Accounts

If you have existing storage accounts, provide the ID per region:

``` hcl
flow_logs = {
  enabled = true
  storage = {
    create                      = false
    external_storage_account_id = "/subscriptions/.../storageAccounts/existing-storage"
  }
}
```

<div class="warning">

The `external_storage_account_id` option only supports a single storage
account. For multi-region deployments, use `storage.create = true` to
create per-region storage accounts.

</div>

<div class="important">

Azure requires flow logs storage accounts to be in the **same region**
as the monitored VNet. This module creates one storage account per hub
region in the connectivity subscription when
`flow_logs.storage.create = true`.

</div>

### Azure Monitor Private Link Scope

AMPLS is **enabled by default** to provide private connectivity to Log
Analytics.

Using remote state (recommended):

``` hcl
management_remote_state = {
  storage_account_name = "<storage-account-name>"
}
```

Or provide workspace ID directly:

``` hcl
azure_monitor_private_link = {
  log_analytics_workspace_id = "/subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/log-analytics"
}
```

To disable AMPLS:

``` hcl
azure_monitor_private_link = {
  enabled = false
}
```

### Custom DNS Servers

``` hcl
hubs = {
  uksouth = {
    dns = {
      servers = ["10.0.0.4", "10.0.0.5"]  # Custom upstream DNS
    }
    features = {
      firewall_dns_proxy = true  # Default, shown for clarity
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

### Unit Tests

The module includes Terraform unit tests in `deploy/terraform/tests/`
that validate configuration logic using mock providers. These tests run
in CI when changes are made to the module and do not require Azure
credentials.

#### Running Tests

``` bash
eirctl tests
```

To run a specific test file:

``` bash
eirctl tests TF_TEST_FILTER=tests/hub_networking.tftest.hcl
```

#### Test Coverage

| Test File                   | Test Cases                                                                                                                            | What It Validates                                                                                                                                                                           |
|-----------------------------|---------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `hub_networking.tftest.hcl` | single_hub_networking_defaults, multi_hub_networking, custom_address_space, custom_subnets_merged                                     | Default /16 allocation, subnet CIDR validity and minimum sizes, mesh peering (single/multi), hub index determinism, custom address space overrides, custom subnet merging                   |
| `hub_resources.tftest.hcl`  | hub_defaults, feature_toggles_propagate, ddos_creates_resource_group, ampls_dns_zones_and_diagnostics, flow_logs_enabled_with_storage | Feature flag defaults and propagation, hub filtering, NSG rules, availability zones, diagnostics enablement, DDoS resource group and settings, AMPLS DNS zone count, flow logs with storage |

#### Writing New Tests

Tests use `.tftest.hcl` files with mock providers. Follow the
established patterns:

- Use `command = plan` with `state_key` to isolate test runs

- Assert against locals and computed values, not Azure API responses

- Enable `parallel = true` at the test level

- Cover default values, feature flag propagation, and edge cases

See the existing test files and `tests/terraform.tfvars` for reference.

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

#### Flow logs storage account creation fails

**Cause**: Storage account names must be globally unique and between
3-24 characters.

**Fix**: The module uses `name_unique` from the naming module to
generate globally unique storage account names. If collisions occur,
change the `random_string` seed or use an external storage account.

#### Firewall alerts not deploying

**Cause**: Alerts require a Log Analytics workspace ID. If
`management_remote_state` is disabled and no workspace ID is provided
directly, alerts are skipped.

**Fix**: Ensure management module integration is configured.

#### Flow logs validation fails

    Error: Flow logs require network_watcher.enabled = true

**Cause**: Flow logs depend on Network Watcher. Either Network Watcher
is disabled or no storage is configured.

**Fix**: Ensure both are enabled:

``` hcl
network_watcher = { enabled = true }
flow_logs = {
  enabled = true
  storage = { create = true }
}
```

## API Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                         | Version  |
|------------------------------------------------------------------------------|----------|
| <span id="requirement_terraform"></span> [terraform](#requirement_terraform) | ~> 1.12 |
| <span id="requirement_azapi"></span> [azapi](#requirement_azapi)             | ~> 2.0  |
| <span id="requirement_azurerm"></span> [azurerm](#requirement_azurerm)       | ~> 4.0  |
| <span id="requirement_random"></span> [random](#requirement_random)          | ~> 3.8  |

## Providers

| Name                                                                   | Version |
|------------------------------------------------------------------------|---------|
| <span id="provider_azurerm"></span> [azurerm](#provider_azurerm)       | ~> 4.0 |
| <span id="provider_random"></span> [random](#provider_random)          | ~> 3.8 |
| <span id="provider_terraform"></span> [terraform](#provider_terraform) | n/a     |

## Modules

| Name                                                                                                   | Source                                                    | Version |
|--------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|---------|
| <span id="module_azure_regions"></span> [azure_regions](#module_azure_regions)                         | Azure/avm-utl-regions/azurerm                             | 0.9.3   |
| <span id="module_flow_logs_storage"></span> [flow_logs_storage](#module_flow_logs_storage)             | Azure/avm-res-storage-storageaccount/azurerm              | 0.6.7   |
| <span id="module_hub_and_spoke_vnet"></span> [hub_and_spoke_vnet](#module_hub_and_spoke_vnet)          | Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm | 0.16.8  |
| <span id="module_naming"></span> [naming](#module_naming)                                              | Azure/naming/azurerm                                      | 0.4.3   |
| <span id="module_nsg_private_endpoints"></span> [nsg_private_endpoints](#module_nsg_private_endpoints) | Azure/avm-res-network-networksecuritygroup/azurerm        | 0.5.1   |
| <span id="module_resource_groups"></span> [resource_groups](#module_resource_groups)                   | Azure/avm-res-resources-resourcegroup/azurerm             | 0.2.1   |

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
| [azurerm_monitor_metric_alert.vpn_p2s_connections](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                         | resource    |
| [azurerm_monitor_metric_alert.vpn_tunnel_egress](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                           | resource    |
| [azurerm_monitor_private_link_scope.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scope)                                            | resource    |
| [azurerm_monitor_private_link_scoped_service.log_analytics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scoped_service)                 | resource    |
| [azurerm_network_watcher.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher)                                                                  | resource    |
| [azurerm_network_watcher_flow_log.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log)                                                | resource    |
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
resources (hub networks, firewalls, DNS).</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p>n/a</p></td>
<td style="text-align: left;"><p>yes</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span id="input_hubs"></span> <a
href="#input_hubs">hubs</a></p></td>
<td style="text-align: left;"><p>Hub virtual network configurations
keyed by Azure region name.</p></td>
<td style="text-align: left;"><pre><code>map(object({
    enabled       = optional(bool, true)
    address_space = optional(string)
&#10;    features = optional(object({
      firewall               = optional(bool, true)
      firewall_sku           = optional(string, &quot;Standard&quot;)
      firewall_management_ip = optional(bool, false)
      firewall_dns_proxy     = optional(bool, true)
      bastion                = optional(bool, false)
      vpn_gateway            = optional(bool, false)
      expressroute_gateway   = optional(bool, false)
      private_dns_zones      = optional(bool, true)
      private_dns_resolver   = optional(bool, false)
      auto_registration_zone = optional(bool, false)
      availability_zones     = optional(list(string))
    }), {})
&#10;    subnets = optional(object({
      firewall_address_prefix             = optional(string)
      firewall_management_address_prefix  = optional(string)
      bastion_address_prefix              = optional(string)
      gateway_address_prefix              = optional(string)
      private_dns_resolver_address_prefix = optional(string)
      private_endpoints_address_prefix    = optional(string)
    }), {})
&#10;    custom_subnets = optional(map(object({
      name                                          = string
      address_prefixes                              = list(string)
      network_security_group_id                     = optional(string)
      route_table_id                                = optional(string)
      service_endpoints                             = optional(list(string))
      private_endpoint_network_policies             = optional(string, &quot;Enabled&quot;)
      private_link_service_network_policies_enabled = optional(bool, true)
      delegation = optional(object({
        name         = string
        service_name = string
        actions      = optional(list(string))
      }))
    })), {})
&#10;    dns = optional(object({
      auto_registration_zone_name = optional(string)
      servers                     = optional(list(string))
    }), {})
&#10;    name_overrides = optional(object({
      resource_group       = optional(string)
      virtual_network      = optional(string)
      firewall             = optional(string)
      firewall_policy      = optional(string)
      bastion              = optional(string)
      vpn_gateway          = optional(string)
      expressroute_gateway = optional(string)
      private_dns_resolver = optional(string)
      route_table_firewall = optional(string)
      route_table_user     = optional(string)
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
Disabled by default due to significant cost (~£2,200/month).</p></td>
<td style="text-align: left;"><pre><code>object({
    enabled = optional(bool, false)
    name    = optional(string)
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
traffic analysis. Disabled by default.</p>
<pre><code>Per Microsoft documentation, the storage account MUST be in the same region as the VNet.
This module creates a storage account per hub region to ensure compliance.</code></pre>
<pre><code>When enabled, creates:
- Storage account per hub region
- VNet flow logs for each hub virtual network</code></pre>
<pre><code>Storage options:
- create: Set to true (default) to create storage accounts
- external_storage_account_id: If create=false, provide an existing storage account ID
  (must be in same region as hub VNet)</code></pre>
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
<td style="text-align: left;"><p>Configuration for fetching management
landing zone outputs via remote state. Enabled by default - set enabled
= false for local testing.</p></td>
<td style="text-align: left;"><pre><code>object({
    enabled              = optional(bool, true)
    backend              = optional(string, &quot;azurerm&quot;)
    workspace            = optional(string, null)
    storage_account_name = optional(string, null)
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
Group on the private endpoints subnet.</p>
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
Internet</p></td>
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

| Name                                                                                                                                    | Description                                                                                                         |
|-----------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| <span id="output_ampls_id"></span> [ampls_id](#output_ampls_id)                                                                         | AMPLS resource ID.                                                                                                  |
| <span id="output_ampls_name"></span> [ampls_name](#output_ampls_name)                                                                   | AMPLS name.                                                                                                         |
| <span id="output_ampls_private_endpoint_ids"></span> [ampls_private_endpoint_ids](#output_ampls_private_endpoint_ids)                   | AMPLS private endpoint IDs, keyed by region.                                                                        |
| <span id="output_ampls_private_ip_addresses"></span> [ampls_private_ip_addresses](#output_ampls_private_ip_addresses)                   | AMPLS private IPs, keyed by region.                                                                                 |
| <span id="output_ampls_resource_group_name"></span> [ampls_resource_group_name](#output_ampls_resource_group_name)                      | Resource group containing AMPLS.                                                                                    |
| <span id="output_bastion_diagnostic_setting_ids"></span> [bastion_diagnostic_setting_ids](#output_bastion_diagnostic_setting_ids)       | Diagnostic setting IDs for Bastion hosts, keyed by region.                                                          |
| <span id="output_bastion_host_dns_names"></span> [bastion_host_dns_names](#output_bastion_host_dns_names)                               | Bastion DNS names, keyed by region.                                                                                 |
| <span id="output_bastion_host_public_ip_addresses"></span> [bastion_host_public_ip_addresses](#output_bastion_host_public_ip_addresses) | Bastion public IPs, keyed by region.                                                                                |
| <span id="output_bastion_host_resource_ids"></span> [bastion_host_resource_ids](#output_bastion_host_resource_ids)                      | Bastion host resource IDs.                                                                                          |
| <span id="output_dns_server_ip_addresses"></span> [dns_server_ip_addresses](#output_dns_server_ip_addresses)                            | DNS server IPs (firewall private IP when DNS Proxy enabled, or DNS Resolver IPs).                                   |
| <span id="output_firewall_alert_ids"></span> [firewall_alert_ids](#output_firewall_alert_ids)                                           | Firewall metric alert IDs, keyed by region and alert type.                                                          |
| <span id="output_firewall_diagnostic_setting_ids"></span> [firewall_diagnostic_setting_ids](#output_firewall_diagnostic_setting_ids)    | Diagnostic setting IDs for firewall.                                                                                |
| <span id="output_firewall_policies"></span> [firewall_policies](#output_firewall_policies)                                              | Firewall Policy resources.                                                                                          |
| <span id="output_firewall_policy_resource_ids"></span> [firewall_policy_resource_ids](#output_firewall_policy_resource_ids)             | Azure Firewall Policy resource IDs, keyed by region.                                                                |
| <span id="output_firewall_private_ip_addresses"></span> [firewall_private_ip_addresses](#output_firewall_private_ip_addresses)          | Firewall private IPs for UDR next-hop.                                                                              |
| <span id="output_firewall_public_ip_addresses"></span> [firewall_public_ip_addresses](#output_firewall_public_ip_addresses)             | Firewall public IPs, keyed by region.                                                                               |
| <span id="output_firewall_resource_ids"></span> [firewall_resource_ids](#output_firewall_resource_ids)                                  | Azure Firewall resource IDs, keyed by region.                                                                       |
| <span id="output_firewall_resource_names"></span> [firewall_resource_names](#output_firewall_resource_names)                            | Azure Firewall names, keyed by region.                                                                              |
| <span id="output_flow_log_ids"></span> [flow_log_ids](#output_flow_log_ids)                                                             | VNet Flow Log resource IDs, keyed by region.                                                                        |
| <span id="output_flow_logs_storage_account_ids"></span> [flow_logs_storage_account_ids](#output_flow_logs_storage_account_ids)          | Flow logs storage account IDs, keyed by region. Storage accounts are created per-region to meet Azure requirements. |
| <span id="output_flow_logs_storage_account_names"></span> [flow_logs_storage_account_names](#output_flow_logs_storage_account_names)    | Flow logs storage account names, keyed by region.                                                                   |
| <span id="output_gateway_alert_ids"></span> [gateway_alert_ids](#output_gateway_alert_ids)                                              | Gateway metric alert IDs, keyed by region and alert type.                                                           |
| <span id="output_gateway_diagnostic_setting_ids"></span> [gateway_diagnostic_setting_ids](#output_gateway_diagnostic_setting_ids)       | Diagnostic setting IDs for VPN and ExpressRoute gateways, keyed by type and region.                                 |
| <span id="output_hub_address_spaces"></span> [hub_address_spaces](#output_hub_address_spaces)                                           | Address space per hub.                                                                                              |
| <span id="output_hub_regions"></span> [hub_regions](#output_hub_regions)                                                                | Regions where hubs are deployed.                                                                                    |
| <span id="output_network_watcher_ids"></span> [network_watcher_ids](#output_network_watcher_ids)                                        | Network Watcher resource IDs, keyed by region.                                                                      |
| <span id="output_primary_hub_region"></span> [primary_hub_region](#output_primary_hub_region)                                           | Primary hub region (first alphabetically).                                                                          |
| <span id="output_private_dns_zone_resource_ids"></span> [private_dns_zone_resource_ids](#output_private_dns_zone_resource_ids)          | Private DNS zone resource IDs for spoke VNet linking. Keyed by region, then zone key.                               |
| <span id="output_private_endpoints_nsg_ids"></span> [private_endpoints_nsg_ids](#output_private_endpoints_nsg_ids)                      | NSG resource IDs for private endpoints subnets, keyed by region.                                                    |
| <span id="output_private_endpoints_nsg_names"></span> [private_endpoints_nsg_names](#output_private_endpoints_nsg_names)                | NSG names for private endpoints subnets, keyed by region.                                                           |
| <span id="output_resource_group_ids"></span> [resource_group_ids](#output_resource_group_ids)                                           | Resource group IDs.                                                                                                 |
| <span id="output_resource_group_names"></span> [resource_group_names](#output_resource_group_names)                                     | Resource group names.                                                                                               |
| <span id="output_route_table_user_subnets_ids"></span> [route_table_user_subnets_ids](#output_route_table_user_subnets_ids)             | Route table IDs for spoke subnet association (routes traffic through firewall).                                     |
| <span id="output_route_tables_firewall"></span> [route_tables_firewall](#output_route_tables_firewall)                                  | Route tables for firewall subnets.                                                                                  |
| <span id="output_route_tables_user_subnets"></span> [route_tables_user_subnets](#output_route_tables_user_subnets)                      | Route tables for spoke subnets.                                                                                     |
| <span id="output_subnet_resource_ids"></span> [subnet_resource_ids](#output_subnet_resource_ids)                                        | Hub subnet resource IDs for UDR association. Keyed by region.                                                       |
| <span id="output_virtual_network_resource_ids"></span> [virtual_network_resource_ids](#output_virtual_network_resource_ids)             | Hub VNet resource IDs.                                                                                              |
| <span id="output_virtual_network_resource_names"></span> [virtual_network_resource_names](#output_virtual_network_resource_names)       | Hub VNet names, keyed by region.                                                                                    |

<!-- END_TF_DOCS -->

## Support

For issues, questions, or contributions related to this module, please
contact the Ensono Stacks team.

## License

Copyright (c) 2026 Ensono

This project is licensed under the MIT License.
