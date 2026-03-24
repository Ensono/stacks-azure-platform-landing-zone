# GitHub Copilot Instructions for Stacks Azure Platform Landing Zone

## Priority Guidelines

When generating code for this repository:

1. **Version Compatibility**: Use only Terraform ~> 1.12, AzureRM ~> 4.0, AzAPI ~> 2.0
2. **Context Files**: Prioritize patterns from `.github/instructions/` directory
3. **Codebase Patterns**: Follow established patterns in existing modules
4. **Module Alignment**: Keep hub_spoke and virtual_wan modules aligned where possible
5. **Azure Verified Modules**: Always use AVM modules for new resources

## Technology Stack

| Component | Version | Source |
|-----------|---------|--------|
| Terraform | ~> 1.12 | `versions.tf` |
| AzureRM Provider | ~> 4.0 | `versions.tf` |
| AzAPI Provider | ~> 2.0 | `versions.tf` |
| Azure Naming Module | 0.4.3 | `naming.tf` |
| AVM Hub-Spoke | 0.16.8 | `hub_and_spoke_vnet.tf` |
| AVM Virtual WAN | 0.13.5 | `virtual.wan.tf` |
| AVM Storage | 0.6.7 | `flow_logs_storage.tf` |

## Project Overview

This repository provides starter modules for deploying Azure Landing Zones using **Azure Verified Modules (AVM)**. There are three primary modules:

- **Management Landing Zone** (`src/management/`) - Deploys management groups, policies, and management resources
- **Connectivity Landing Zone Hub-Spoke** (`src/connectivity-hub-spoke/`) - Deploys hub-and-spoke network topology
- **Connectivity Landing Zone Virtual WAN** (`src/connectivity-virtual-wan/`) - Deploys Virtual WAN network topology

These modules are imported into landing zone repositories created by the bootstrap module. CI/CD pipelines are managed by the bootstrap, not in this repo.

## Subscription Requirements

Different deployment scenarios require different subscriptions:

| Template | Required Subscriptions |
|----------|----------------------|
| Management (resources only) | `management` |
| Management (full ALZ with management groups) | `connectivity`, `identity`, `management` |
| Connectivity Hub-Spoke | `connectivity`, `management` |
| Connectivity Virtual WAN | `connectivity`, `management` |

Subscription IDs are passed via `subscription_ids` map in `terraform.tfvars`. See `deploy/terraform/examples/` in each template for configuration examples.

## Architecture

### Management Landing Zone Module Chain

```
management_resources → management_groups
```

1. **management_resources** - Deploys Log Analytics Workspace, Data Collection Rules, and managed identities (wraps [Azure/avm-ptn-alz-management](https://registry.terraform.io/modules/Azure/avm-ptn-alz-management/azurerm/latest))
2. **management_groups** - Deploys management group hierarchy and policies (wraps [Azure/avm-ptn-alz](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest))

### Connectivity Landing Zone Hub-Spoke Module Chain

```
resource_groups → hub_and_spoke_vnet
```

1. **resource_groups** - Deploys resource groups using `for_each` from config (wraps [Azure/avm-res-resources-resourcegroup](https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm/latest))
2. **hub_and_spoke_vnet** - Deploys hub virtual networks, firewalls, bastion, DNS, and gateways (wraps [Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm/latest))

### Connectivity Landing Zone Virtual WAN Module Chain

```
resource_groups → virtual_wan
```

1. **resource_groups** - Deploys resource groups using `for_each` from config (wraps [Azure/avm-res-resources-resourcegroup](https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm/latest))
2. **virtual_wan** - Deploys Virtual WAN, virtual hubs, firewalls, bastion, DNS, and gateways (wraps [Azure/avm-ptn-alz-connectivity-virtual-wan](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm/latest))

### Key Design Patterns

- **Conditional modules via `count`** (management): Root modules use `count = var.*_enabled ? 1 : 0`. Access outputs with `module.name[0].output` and wrap in `try(..., null)` for safety
- **Always-on modules** (connectivity modules): The connectivity modules always deploy; individual features (firewall, bastion, etc.) are toggled via tfvars settings
- **Template string replacements**: Use `$${variable_name}` syntax in tfvars for dynamic values (e.g., `$${starter_location_01}`, `$${subscription_id_connectivity}`)
- **Multi-region support**: Connectivity modules support multiple hubs via `starter_locations` list and per-region settings in tfvars

## Code Patterns

### File Organization

```
deploy/terraform/
├── main.tf                    # Resource groups module
├── naming.tf                  # Azure naming module
├── providers.tf               # Provider configuration
├── regions.tf                 # Azure regions module
├── versions.tf                # Terraform and provider versions
├── outputs.tf                 # All outputs
├── variables.tf               # Core variables
├── variables_*.tf             # Grouped variables (hubs, regions, etc.)
├── locals_*.tf                # Grouped locals (naming, config, etc.)
├── *_diagnostics.tf           # Diagnostic settings by resource type
├── *_alerts.tf                # Metric alerts by resource type
├── tests/                     # Unit tests (.tftest.hcl)
└── examples/                  # Example tfvars
```

### Locals Pattern (from actual code)

```hcl
locals {
  # Filter pattern - used throughout codebase
  enabled_hubs = {
    for region, hub in var.hubs : region => hub
    if hub.enabled
  }

  # Conditional with Log Analytics check
  firewalls_with_diagnostics = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.firewall && local.log_analytics_workspace_id != null
  }
}
```

### Resource Naming Pattern

```hcl
# Hub resource names with coalesce for overrides
hub_names = {
  for region, hub in local.enabled_hubs : region => {
    resource_group  = coalesce(hub.name_overrides.resource_group, module.naming["hub-${region}"].resource_group.name)
    virtual_network = coalesce(hub.name_overrides.virtual_network, module.naming["hub-${region}"].virtual_network.name)
    firewall        = coalesce(hub.name_overrides.firewall, local.naming_extended["hub-${region}"].firewall.name)
  }
}
```

### Diagnostic Settings Pattern

```hcl
# File header comment
# [Resource Type] Diagnostic Settings
# Reference: https://learn.microsoft.com/...

locals {
  resources_with_diagnostics = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.resource_type && local.log_analytics_workspace_id != null
  }
}

resource "azurerm_monitor_diagnostic_setting" "resource_name" {
  for_each = local.resources_with_diagnostics

  name                           = "diag-resource-${each.key}"
  target_resource_id             = module.main_module.resource_ids[each.key]
  log_analytics_workspace_id     = local.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log { category = "CategoryName" }
  enabled_metric { category = "AllMetrics" }

  depends_on = [module.main_module]
}
```

### Metric Alerts Pattern

```hcl
# File header comment
# [Resource Type] Metric Alerts
# Reference: https://learn.microsoft.com/...

locals {
  resources_with_alerts = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.resource_type && local.log_analytics_workspace_id != null
  }
}

# Alert comment with severity
resource "azurerm_monitor_metric_alert" "alert_name" {
  for_each = local.resources_with_alerts

  name                = "alert-resource-type-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.main_module.resource_ids[each.key]]
  description         = "Alert description in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/resourceType"
    metric_name      = "MetricName"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  tags = var.tags
}
```

### Output Pattern

```hcl
output "resource_ids" {
  description = "Resource IDs, keyed by region."
  value       = module.main_module.resource_ids
}

output "diagnostic_setting_ids" {
  description = "Diagnostic setting IDs, keyed by region."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.resource : k => v.id }
}

output "alert_ids" {
  description = "Metric alert IDs, keyed by region and alert type."
  value = {
    alert_type_1 = { for k, v in azurerm_monitor_metric_alert.alert_1 : k => v.id }
    alert_type_2 = { for k, v in azurerm_monitor_metric_alert.alert_2 : k => v.id }
  }
}
```

### Variable Pattern

```hcl
variable "feature_name" {
  type = object({
    enabled = optional(bool, true)
    setting = optional(string, "default")
    nested = optional(object({
      option_a = optional(bool, false)
      option_b = optional(number, 90)
    }), {})
  })
  default     = {}
  description = "Feature configuration with sensible defaults."

  validation {
    condition     = var.feature_name.nested.option_b >= 0 && var.feature_name.nested.option_b <= 365
    error_message = "Option B must be between 0 and 365."
  }
}
```

## Module Alignment Rules

When modifying connectivity modules, ensure **hub_spoke** and **virtual_wan** remain aligned:

| File | Must Match |
|------|-----------|
| `*_alerts.tf` | Same locals structure, same alert types |
| `*_diagnostics.tf` | Same locals structure, same log categories |
| `variables_*.tf` | Same variable names and types |
| `outputs.tf` | Same output names and structure |

### Differences by Design

| Aspect | Hub-Spoke | Virtual WAN |
|--------|-----------|-------------|
| Module reference | `module.hub_and_spoke_vnet` | `module.virtual_wan` |
| VPN Gateway ID | VNet Gateway in RG | VPN Gateway in Virtual Hub |
| Flow logs target | Hub VNet | Sidecar VNet |
| P2S VPN logs | Yes | No (not supported) |
| Virtual Hub resources | N/A | `virtual_hub_diagnostics.tf`, `virtual_hub_alerts.tf` |

## Developer Workflows

### Task Runner (eirctl)

Run from the module directory (e.g., `src/management/` or `src/connectivity-hub-spoke/`):

```bash
eirctl lint              # YAML lint → terraform fmt → validate → tflint
eirctl scan              # Checkov security scan
eirctl documentation     # Generate terraform-docs for all modules
eirctl infrastructure:plan # terraform init → plan
eirctl infrastructure:apply
```

### Unit Testing

Unit tests validate configuration logic using mock providers (no Azure credentials required):

```bash
cd deploy/terraform
terraform test              # Run all tests
terraform test -filter=tests/hub_networking.tftest.hcl  # Run specific test
```

Test files are located in `deploy/terraform/tests/` and use `.tftest.hcl` extension.

### Test File Pattern

```hcl
# Test: [Test Name]
# Validates [what is being tested]

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      object_id       = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azapi" {
  mock_data "azapi_resource_action" {
    defaults = {
      output = {
        value = [{ name = "uksouth", displayName = "UK South", ... }]
      }
    }
  }
}

mock_provider "random" {}
mock_provider "local" {}
mock_provider "modtm" {}

override_data {
  target = data.terraform_remote_state.management
  values = { outputs = {} }
}

test {
  parallel = true
}

run "test_case_name" {
  command   = plan
  state_key = "test_state"

  variables {
    hubs = { uksouth = { enabled = true, ... } }
  }

  assert {
    condition     = local.some_value == "expected"
    error_message = "Description of what failed"
  }
}
```

### Documentation Generation

- Root README: Auto-generated from `_header.md` via terraform-docs
- Child modules: Each has `_header.md` for custom content; run `terraform-docs` from `deploy/terraform/modules/`
- Config: `.terraform-docs.yml` in each directory controls output

## ALZ Library Structure

Located at `deploy/terraform/lib/` (management only):

- `architecture_definitions/` - Management group hierarchy (e.g., `alz_custom.alz_architecture_definition.yaml`)
- `archetype_definitions/` - Policy overrides per management group (e.g., `root_custom.alz_archetype_override.yaml`)

To customize policies, modify the `*_custom.alz_archetype_override.yaml` files, not the base archetypes.

## Common Patterns

### Adding a New Output

```hcl
# In root outputs.tf - handle count-based modules
output "example" {
  value = try(module.management_resources[0].some_output, null)
}
```

### Custom Replacements in tfvars

```hcl
custom_replacements = {
  names = { my_resource_name = "custom-name" }
  resource_group_identifiers = {
    my_rg_id = "/subscriptions/$${subscription_id_management}/resourcegroups/$${my_resource_name}"
  }
  resource_identifiers = {
    my_resource_id = "$${my_rg_id}/providers/Microsoft.Example/resources/$${my_resource_name}"
  }
}
```

## File Naming Conventions

- `variables.*.tf` - Group variables by concern (e.g., `variables.naming.tf`, `variables.management.groups.tf`)
- `locals_*.tf` - Group locals by concern (e.g., `locals_naming.tf`, `locals_hub_config.tf`)
- `*_diagnostics.tf` - Diagnostic settings for resource type
- `*_alerts.tf` - Metric alerts for resource type
- `_header.md` - Custom documentation header for terraform-docs
- `*.alz_archetype_override.yaml` - Policy customizations per management group
