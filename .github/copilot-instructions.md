# GitHub Copilot Instructions for Stacks Azure Platform Landing Zone

## Priority Guidelines

When generating code for this repository:

1. **Version Compatibility**: Use only Terraform ~> 1.12, AzureRM ~> 4.0, AzAPI ~> 2.0. Never use features unavailable in these versions
2. **Context Files**: Prioritize patterns and standards defined in `.github/instructions/` directory
3. **Codebase Patterns**: When context files don't provide specific guidance, scan existing modules for established patterns
4. **Module Alignment**: Keep `hub_spoke` and `virtual_wan` modules aligned where possible
5. **Azure Verified Modules**: Always use AVM modules for new Azure resources
6. **Code Quality**: Prioritize maintainability, security, and testability in all generated code

## Technology Stack

### Exact Versions (from `versions.tf`)

| Component | Version | Source |
|-----------|---------|--------|
| Terraform CLI | ~> 1.12 (local: 1.14.7) | `versions.tf`, `.terraform-version` |
| AzureRM Provider | ~> 4.0 | `versions.tf` |
| AzAPI Provider | ~> 2.0 | `versions.tf` |
| ALZ Provider | 0.20.2 (exact) | `versions.tf` (management only) |
| Modtm Provider | ~> 0.3 | `versions.tf` (connectivity only) |
| Local Provider | ~> 2.5 | `versions.tf` (connectivity only) |
| Random Provider | ~> 3.8 | `versions.tf` (connectivity only) |

### Module Versions (from module blocks)

| Module | Version | Source | Used In |
|--------|---------|--------|---------|
| Azure Naming | 0.4.3 | `Azure/naming/azurerm` | All modules |
| Azure Regions | 0.9.3 | `Azure/avm-utl-regions/azurerm` | All modules |
| Resource Groups | 0.2.1 | `Azure/avm-res-resources-resourcegroup/azurerm` | All modules |
| Hub-Spoke Connectivity | 0.16.8 | `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` | Hub-Spoke |
| Virtual WAN Connectivity | 0.13.5 | `Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm` | Virtual WAN |
| Storage Account | 0.6.7 | `Azure/avm-res-storage-storageaccount/azurerm` | Connectivity |
| Management Resources | 0.9.0 | `Azure/avm-ptn-alz-management/azurerm` | Management |
| Management Groups (ALZ) | 0.18.0 | `Azure/avm-ptn-alz/azurerm` | Management |

**Never suggest module versions higher than those listed. Check the Terraform Registry for compatible versions when adding new AVM modules.**

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

## Code Quality Standards

### Maintainability

- Keep locals grouped by concern in separate `locals_*.tf` files (e.g., `locals_naming.tf`, `locals_hub_config.tf`)
- Group variables by feature area in `variables_*.tf` files (e.g., `variables_hubs.tf`, `variables_regions.tf`)
- Use `coalesce()` for name overrides and `try(..., null)` for safe access to optional values
- Extract repeated `for_each` filter expressions into named locals (e.g., `firewalls_with_diagnostics`, `vpn_gateways_with_diagnostics`)
- Keep functions focused on single responsibilities; each `*_diagnostics.tf` and `*_alerts.tf` file handles exactly one resource type

### Security

- Never store secrets in Terraform files or state; use managed identities instead of passwords/keys
- Use `use_azuread_auth = true` in backend configuration (as established in `versions.tf`)
- Use `storage_use_azuread = true` in the AzureRM provider (as established in `providers.tf`)
- Set `resource_provider_registrations = "none"` and `skip_provider_registration = true` to follow least-privilege principles
- Use resource group locks (`resource_group_lock_enabled = true` by default) to prevent accidental deletion
- Apply `precondition` lifecycle blocks in `terraform_data` resources for input validation (see `data_remote_state.tf`)
- Never hardcode subscription IDs, tenant IDs, or other sensitive identifiers
- Mark sensitive variables with `sensitive = true`; never output sensitive data without marking the output sensitive

### Testability

- Write unit tests using `.tftest.hcl` files with mock providers (no Azure credentials required)
- Test configuration logic (locals, computed values, conditional resources), not Azure API behaviour
- Use `command = plan` with `state_key` to isolate test runs
- Enable `parallel = true` at the test level
- Assert against locals and computed values rather than resource attributes
- Cover: default values, feature flag propagation, multi-region scenarios, custom overrides, and edge cases

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
├── data_providers.tf          # Data sources (azurerm_client_config)
├── data_remote_state.tf       # Remote state + validation preconditions
├── *_diagnostics.tf           # Diagnostic settings by resource type
├── *_alerts.tf                # Metric alerts by resource type
├── tests/                     # Unit tests (.tftest.hcl)
└── examples/                  # Example tfvars
```

### Provider Configuration Pattern

```hcl
# Connectivity modules
provider "azapi" {
  enable_preflight           = true
  skip_provider_registration = true
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}

# Management module adds ALZ provider
provider "alz" {
  library_overwrite_enabled = true
  library_references = [{ custom_url = "${path.root}/lib" }]
}
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
# Naming module instances per region using for_each
module "naming" {
  source   = "Azure/naming/azurerm"
  version  = "0.4.3"
  for_each = local.naming_instances

  prefix = [local.company_prefix]
  suffix = [each.value.component, each.value.region]
}

# CAF prefixes for resources not in naming module
locals {
  caf_prefixes = {
    ampls       = "ampls"
    bastion     = "bas"
    firewall    = "afw"
    route_table = "rt"
  }
}

# Hub resource names with coalesce for overrides
locals {
  hub_names = {
    for region, hub in local.enabled_hubs : region => {
      resource_group  = coalesce(hub.name_overrides.resource_group, module.naming["hub-${region}"].resource_group.name)
      virtual_network = coalesce(hub.name_overrides.virtual_network, module.naming["hub-${region}"].virtual_network.name)
      firewall        = coalesce(hub.name_overrides.firewall, local.naming_extended["hub-${region}"].firewall.name)
    }
  }
}
```

### Remote State and Validation Pattern

```hcl
# Conditional remote state data source
data "terraform_remote_state" "management" {
  count     = var.management_remote_state.enabled ? 1 : 0
  backend   = var.management_remote_state.backend
  workspace = coalesce(var.management_remote_state.workspace, terraform.workspace)
  config    = { ... }
}

# Safe access with try/coalesce chain for optional remote outputs
locals {
  log_analytics_workspace_id = try(
    coalesce(
      var.azure_monitor_private_link.log_analytics_workspace_id,
      try(local.management_outputs.log_analytics_workspace_id, null)
    ),
    null
  )
}

# Validation using terraform_data with lifecycle preconditions
resource "terraform_data" "validate_ampls_requirements" {
  count = var.azure_monitor_private_link.enabled ? 1 : 0
  lifecycle {
    precondition {
      condition     = local.log_analytics_workspace_id != null
      error_message = "AMPLS requires log_analytics_workspace_id."
    }
  }
}
```

### Diagnostic Settings Pattern

```hcl
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
# [Resource Type] Metric Alerts
# Reference: https://learn.microsoft.com/...

locals {
  resources_with_alerts = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.resource_type && local.log_analytics_workspace_id != null
  }
}

# Severity 1 = Critical, 2 = Warning (comment with severity before each alert)
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
# Simple module passthrough
output "resource_ids" {
  description = "Resource IDs, keyed by region."
  value       = module.main_module.resource_ids
}

# Diagnostic settings - keyed by region
output "diagnostic_setting_ids" {
  description = "Diagnostic setting IDs, keyed by region."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.resource : k => v.id }
}

# Alerts - nested by alert type then region
output "alert_ids" {
  description = "Metric alert IDs, keyed by region and alert type."
  value = {
    alert_type_1 = { for k, v in azurerm_monitor_metric_alert.alert_1 : k => v.id }
    alert_type_2 = { for k, v in azurerm_monitor_metric_alert.alert_2 : k => v.id }
  }
}

# Count-based modules (management) - use try for safety
output "example" {
  description = "Example output from count-based module."
  value       = try(module.management_resources[0].some_output, null)
}
```

### Variable Pattern

```hcl
# Feature variable with nested object, optional fields, and defaults
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

# Complex map(object) variable with multiple validations (see variables_hubs.tf)
variable "hubs" {
  type = map(object({
    enabled       = optional(bool, true)
    address_space = optional(string)
    features = optional(object({
      firewall = optional(bool, true)
      # ...
    }), {})
    name_overrides = optional(object({
      resource_group = optional(string)
      # ...
    }), {})
  }))
  description = "Hub virtual network configurations keyed by Azure region name."

  validation {
    condition     = length(var.hubs) > 0
    error_message = "At least one hub must be defined."
  }
  # Additional validations: max count, key format, CIDR validity, feature dependencies
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
| `data_remote_state.tf` | Same remote state variables and validation logic |
| `flow_logs_storage.tf` | Same storage account configuration |
| `naming.tf` | Same naming module version and structure |
| `regions.tf` | Same regions module version and configuration |

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
        value = [
          {
            name        = "uksouth"
            displayName = "UK South"
            metadata = {
              regionType     = "Physical"
              regionCategory = "Recommended"
              geography      = "United Kingdom"
              geographyGroup = "Europe"
              physicalLocation = "London"
              pairedRegion   = [{ name = "ukwest" }]
            }
          }
          # Add more regions as needed
        ]
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
    hubs = { uksouth = { enabled = true } }
  }

  assert {
    condition     = local.some_value == "expected"
    error_message = "Description of what failed"
  }
}
```

### Test Coverage Expectations

Tests should cover these categories (following established patterns):

| Category | Example Test | File |
|----------|-------------|------|
| Default values | Verify feature defaults are safe/disabled | `hub_resources.tftest.hcl` |
| Feature flag propagation | Enable/disable features and verify locals | `hub_resources.tftest.hcl` |
| Multi-region scenarios | Multiple hubs with unique address spaces | `hub_networking.tftest.hcl` |
| Custom overrides | Override address spaces, names, subnets | `hub_networking.tftest.hcl` |
| Filtering/conditional logic | Enabled/disabled hub filtering | `hub_resources.tftest.hcl` |
| Naming conventions | Verify generated resource names | `naming.tftest.hcl` (management) |
| Validation rules | Test variable validation constraints | Via `expect_failures` |

### Documentation Generation

- Root README: Auto-generated from `_header.md` via terraform-docs
- Config: `.terraform-docs.yml` in `deploy/terraform/` controls output format
- Format: `markdown document` with sections: Header, Requirements, Resources, Inputs, Outputs, Modules
- Output file: `../../README.md` relative to `deploy/terraform/`
- Run: `eirctl documentation` from module root

## ALZ Library Structure

Located at `deploy/terraform/lib/` (management only):

- `architecture_definitions/` - Management group hierarchy (e.g., `alz_custom.alz_architecture_definition.yaml`)
- `archetype_definitions/` - Policy overrides per management group (e.g., `root_custom.alz_archetype_override.yaml`)

To customize policies, modify the `*_custom.alz_archetype_override.yaml` files, not the base archetypes.

## Common Patterns

### Adding a New Feature to Connectivity Modules

1. Add variables in a new `variables_feature.tf` (or extend existing `variables_*.tf`)
2. Add locals in a new `locals_feature.tf` with the filter pattern:
   ```hcl
   locals {
     resources_with_feature = {
       for region, hub in local.enabled_hubs : region => hub
       if hub.features.new_feature && local.log_analytics_workspace_id != null
     }
   }
   ```
3. Add diagnostics in `feature_diagnostics.tf` following the diagnostic settings pattern
4. Add alerts in `feature_alerts.tf` following the metric alerts pattern
5. Add outputs in `outputs.tf` following the output pattern
6. Add tests in `tests/feature.tftest.hcl` following the test file pattern
7. **Replicate across both hub-spoke and virtual-wan modules**

### Adding a New Output

```hcl
# In root outputs.tf - handle count-based modules (management)
output "example" {
  description = "Example output from count-based module."
  value       = try(module.management_resources[0].some_output, null)
}

# In connectivity outputs.tf - keyed by region
output "example_ids" {
  description = "Example resource IDs, keyed by region."
  value       = { for k, v in azurerm_resource.example : k => v.id }
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

| Pattern | Purpose | Examples |
|---------|---------|---------|
| `variables_*.tf` | Group variables by concern | `variables_hubs.tf`, `variables_regions.tf` |
| `locals_*.tf` | Group locals by concern | `locals_naming.tf`, `locals_hub_config.tf` |
| `*_diagnostics.tf` | Diagnostic settings for resource type | `firewall_diagnostics.tf`, `bastion_diagnostics.tf` |
| `*_alerts.tf` | Metric alerts for resource type | `firewall_alerts.tf`, `gateway_alerts.tf` |
| `data_*.tf` | Data sources by category | `data_providers.tf`, `data_remote_state.tf` |
| `_header.md` | Custom documentation header for terraform-docs | One per module |
| `.terraform-docs.yml` | terraform-docs configuration | One per `deploy/terraform/` |
| `*.alz_archetype_override.yaml` | Policy customizations per management group | Management module only |

## General Best Practices

- Follow `snake_case` for all Terraform identifiers (variables, locals, resources, outputs)
- Use `for_each` with maps for multi-region resources; use `count` only for 0-or-1 conditional modules
- Prefer implicit dependencies; use `depends_on` only when the dependency cannot be expressed through references
- Place `for_each`/`count` first in resource blocks, then core attributes, then nested blocks
- Use `terraform fmt` for consistent formatting (enforced by CI)
- All variables must have `type` and `description`; use `optional()` with defaults for nested objects
- All outputs must have `description`
- Include a Microsoft Learn reference URL as a comment header in diagnostic and alert files
- Use CAF naming conventions via the `Azure/naming/azurerm` module
- Validate inputs at the variable level using `validation` blocks with clear error messages
- Never introduce patterns not found in the existing codebase
