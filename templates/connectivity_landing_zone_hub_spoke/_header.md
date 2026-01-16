# Stacks Azure Platform Landing Zone - Connectivity - Hub and Spoke

Deploys hub virtual networks using Azure Verified Modules (AVM). Supports single or multi-region deployments with automatic IP allocation and CAF-compliant naming.

## Features

| Feature | Default | Description |
|---------|---------|-------------|
| Hub Virtual Networks | ✅ | With mesh peering for multi-region |
| Azure Firewall | ✅ | With firewall policies and management IP |
| Private DNS Zones | ✅ | For Azure Private Link services |
| Private DNS Resolver | ✅ | For hybrid DNS resolution |
| Azure Monitor Private Link | ❌ | Private connectivity to Log Analytics |
| Azure Bastion | ❌ | Secure VM access |
| VPN Gateway | ❌ | Site-to-Site/Point-to-Site VPN |
| ExpressRoute Gateway | ❌ | ExpressRoute connectivity |
| DDoS Protection Plan | ❌ | Shared across all hubs |

## Quick Start

```hcl
company_name                 = "ensono"
connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"

hubs = {
  uksouth = {}
}
```

## Configuration Examples

### Multi-Region Deployment

```hcl
hubs = {
  uksouth = {}
  ukwest  = {}
}
```

IP addresses are calculated automatically:

- First hub: `10.0.0.0/16`
- Second hub: `10.1.0.0/16`

Mesh VNet peering is configured automatically between all hubs.

### Enable Optional Features

```hcl
hubs = {
  uksouth = {
    features = {
      bastion              = true
      vpn_gateway          = true
      expressroute_gateway = true
      availability_zones   = ["1", "2", "3"]
    }
  }
}
```

> **Note:** Availability zones provide 99.99% SLA but incur cross-zone data transfer charges (~£0.01/GB).

### Custom IP Addressing

```hcl
hubs = {
  uksouth = {
    address_space = "172.16.0.0/16"
    subnets = {
      firewall_address_prefix             = "172.16.0.0/26"
      firewall_management_address_prefix  = "172.16.0.64/26"
      bastion_address_prefix              = "172.16.0.128/26"
      gateway_address_prefix              = "172.16.0.192/27"
      private_dns_resolver_address_prefix = "172.16.0.224/28"
    }
  }
}
```

### Custom Resource Names

```hcl
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

```hcl
hubs = {
  uksouth = {
    dns = {
      auto_registration_zone_name = "uksouth.corp.ensono.com"
    }
  }
}
```

### Disable a Hub Temporarily

```hcl
hubs = {
  uksouth = {}
  ukwest  = { enabled = false }
}
```

### Custom Subnets in Hub

```hcl
hubs = {
  uksouth = {
    custom_subnets = {
      management = {
        name             = "snet-management"
        address_prefixes = ["10.0.4.0/24"]
      }
    }
  }
}
```

### Azure Monitor Private Link

Connect Log Analytics privately:

```hcl
azure_monitor_private_link = {
  enabled                    = true
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/log-analytics"
}
```

**Using remote state** (recommended):

```hcl
management_remote_state = {
  enabled              = true
  storage_account_name = "<storage-account-name>"
}

azure_monitor_private_link = {
  enabled = true  # Workspace ID fetched automatically from management module
}
```

Application landing zones can add their own scoped services using the outputs:

```hcl
# In application landing zone
resource "azurerm_monitor_private_link_scoped_service" "app_insights" {
  name                = "appinsights-myapp"
  resource_group_name = data.terraform_remote_state.connectivity.outputs.ampls_resource_group_name
  scope_name          = data.terraform_remote_state.connectivity.outputs.ampls_name
  linked_resource_id  = azurerm_application_insights.this.id
}
```

## IP Address Layout

Default subnet layout within each hub's `/22`:

| Subnet | Size | Default Range (first hub) | Purpose |
|--------|------|--------------------------|---------|
| AzureFirewallSubnet | /26 | 10.0.0.0/26 | Azure Firewall (required name) |
| AzureBastionSubnet | /26 | 10.0.0.64/26 | Azure Bastion (required name) |
| snet-private-endpoints | /26 | 10.0.0.128/26 | Platform private endpoints |
| AzureFirewallManagementSubnet | /26 | 10.0.0.192/26 | Firewall management (required name) |
| GatewaySubnet | /27 | 10.0.1.0/27 | VPN/ExpressRoute (required name) |
| PrivateDnsResolverSubnet | /28 | 10.0.1.32/28 | Private DNS Resolver |

## Testing

Unit tests validate configuration logic without deploying infrastructure. Tests use mock providers to run offline.

### Run Tests

```bash
cd deploy/terraform
terraform test
```

### Test Coverage

| Test File | Description |
|-----------|-------------|
| `feature_toggles.tftest.hcl` | Feature flags propagate correctly to hub configuration |
| `mesh_peering.tftest.hcl` | Mesh peering enabled only for multi-hub deployments |
| `multi_hub_addressing.tftest.hcl` | Multiple hubs get unique, deterministic address spaces |
| `naming_conventions.tftest.hcl` | Resource names follow CAF conventions |
| `subnet_calculations.tftest.hcl` | Subnet CIDRs are valid and meet Azure size requirements |
| `tags.tftest.hcl` | Ensono tags generated and merged correctly |
| `variable_validation.tftest.hcl` | Variable constraints validated |
