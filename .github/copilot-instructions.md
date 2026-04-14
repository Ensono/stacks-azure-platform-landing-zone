# GitHub Copilot Instructions for Stacks Azure Platform Landing Zone

## Priority Guidelines

When generating code for this repository:

1. **Version Compatibility**: Use only Terraform ~> 1.12, AzureRM ~> 4.0, AzAPI ~> 2.0. Never use features unavailable in these versions
2. **Context Files**: Prioritize patterns and standards defined in `.github/instructions/` directory
3. **Codebase Patterns**: When context files don't provide specific guidance, scan existing modules for established patterns
4. **Module Alignment**: Keep `hub_spoke` and `virtual_wan` modules aligned where possible
5. **Azure Verified Modules**: Always use AVM modules for new Azure resources. Check the [Terraform Registry](https://registry.terraform.io/namespaces/Azure) for available AVM modules and verify compatibility with AzureRM ~> 4.0 before use
6. **Architectural Consistency**: Maintain the established module-per-landing-zone architecture with feature toggles, remote state integration, and CAF naming
7. **Code Quality**: Prioritize maintainability, security, and testability in all generated code
8. **Never introduce patterns not found in the existing codebase**

## Technology Version Detection

Before generating code, verify exact versions from project files. Never use features beyond these versions.

### Exact Versions (from `versions.tf`)

| Component | Version Constraint | Source |
|-----------|-------------------|--------|
| Terraform CLI | `~> 1.12` | `versions.tf`, `.terraform-version` |
| AzureRM Provider | `~> 4.0` | `versions.tf` |
| AzAPI Provider | `~> 2.0` | `versions.tf` |
| ALZ Provider | `0.20.2` (exact pin) | `versions.tf` (management only) |
| Random Provider | `~> 3.8` | `versions.tf` (connectivity only) |

### Module Versions (from module blocks)

| Module | Version | Source | Used In |
|--------|---------|--------|---------|
| Azure Naming | 0.4.3 | `Azure/naming/azurerm` | All modules |
| Azure Regions | 0.9.3 | `Azure/avm-utl-regions/azurerm` | All modules |
| Resource Groups | 0.2.1 | `Azure/avm-res-resources-resourcegroup/azurerm` | All modules |
| Hub-Spoke Connectivity | 0.16.8 | `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` | Hub-Spoke |
| Virtual WAN Connectivity | 0.13.5 | `Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm` | Virtual WAN |
| Storage Account | 0.6.7 | `Azure/avm-res-storage-storageaccount/azurerm` | Connectivity |
| Network Security Group | 0.5.1 | `Azure/avm-res-network-networksecuritygroup/azurerm` | Connectivity |
| Management Resources | 0.9.0 | `Azure/avm-ptn-alz-management/azurerm` | Management |
| Management Groups (ALZ) | 0.18.0 | `Azure/avm-ptn-alz/azurerm` | Management |

**Never suggest module versions higher than those listed. Check the Terraform Registry for compatible versions when adding new AVM modules.**

## Context Files

Prioritize the following files in `.github/instructions/` directory:

- **terraform-azure.instructions.md**: Azure-specific Terraform guidance, AVM usage, secrets management, folder structure
- **terraform.instructions.md**: General Terraform conventions, security, modularity, style, formatting, documentation, testing

## Project Overview

This repository provides starter modules for deploying Azure Landing Zones using **Azure Verified Modules (AVM)**. The primary modules are:

- **Management Landing Zone** (`src/management/`) — Deploys management groups, policies, Log Analytics Workspace, and Data Collection Rules
- **Connectivity Landing Zone Hub-Spoke** (`src/connectivity-hub-spoke/`) — Deploys hub-and-spoke network topology with firewalls, bastion, DNS, gateways, AMPLS, flow logs
- **Connectivity Landing Zone Virtual WAN** (`src/connectivity-virtual-wan/`) — Deploys Virtual WAN network topology with equivalent features

These modules are imported into landing zone repositories created by the bootstrap module. CI/CD pipelines are managed by the bootstrap, not in this repo.

## Subscription Requirements

Different deployment scenarios require different subscriptions:

| Template | Required Subscriptions |
|----------|----------------------|
| Management (resources only) | `management` |
| Management (full ALZ with management groups) | `connectivity`, `identity`, `management` |
| Connectivity Hub-Spoke | `connectivity`, `management` |
| Connectivity Virtual WAN | `connectivity`, `management` |

Subscription IDs are passed via variables in `terraform.tfvars`. See `deploy/terraform/examples/` in each template for configuration examples.

## Architecture

### Management Landing Zone Module Chain

```
management_resources → management_groups
```

1. **management_resources** — Deploys Log Analytics Workspace, Data Collection Rules, and managed identities (wraps [Azure/avm-ptn-alz-management](https://registry.terraform.io/modules/Azure/avm-ptn-alz-management/azurerm/latest))
2. **management_groups** — Deploys management group hierarchy and policies (wraps [Azure/avm-ptn-alz](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest))

### Connectivity Landing Zone Hub-Spoke Module Chain

```
resource_groups → hub_and_spoke_vnet
```

1. **resource_groups** — Deploys resource groups using `for_each` from config (wraps [Azure/avm-res-resources-resourcegroup](https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm/latest))
2. **hub_and_spoke_vnet** — Deploys hub virtual networks, firewalls, bastion, DNS, and gateways (wraps [Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm/latest))

### Connectivity Landing Zone Virtual WAN Module Chain

```
resource_groups → virtual_wan
```

1. **resource_groups** — Deploys resource groups using `for_each` from config
2. **virtual_wan** — Deploys Virtual WAN, virtual hubs, firewalls, bastion, DNS, and gateways (wraps [Azure/avm-ptn-alz-connectivity-virtual-wan](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm/latest))

### Key Design Patterns

- **Conditional modules via `count`** (management): Root modules use `count = var.*_enabled ? 1 : 0`. Access outputs with `module.name[0].output` and wrap in `try(..., null)` for safety
- **Always-on modules** (connectivity): The connectivity modules always deploy; individual features (firewall, bastion, etc.) are toggled via tfvars settings
- **Template string replacements**: Use `$${variable_name}` syntax in tfvars for dynamic values (e.g., `$${starter_location_01}`, `$${subscription_id_connectivity}`)
- **Multi-region support**: Connectivity modules support multiple hubs via sorted region keys and per-region settings
- **Feature-gated diagnostics/alerts**: Each diagnostic/alert resource checks both the feature flag AND `local.log_analytics_workspace_id != null`
- **Remote state chaining**: Downstream modules consume upstream outputs via `data.terraform_remote_state` with `try`/`coalesce` safety wrappers

## Code Quality Standards

### Maintainability

- Keep locals grouped by concern in separate `locals_*.tf` files (e.g., `locals_naming.tf`, `locals_hub_config.tf`)
- Group variables by feature area in `variables_*.tf` files (e.g., `variables_hubs.tf`, `variables_regions.tf`)
- Use `coalesce()` for name overrides and `try(..., null)` for safe access to optional values
- Extract repeated `for_each` filter expressions into named locals (e.g., `firewalls_with_diagnostics`, `vpn_gateways_with_diagnostics`)
- Keep functions focused on single responsibilities; each `*_diagnostics.tf` and `*_alerts.tf` file handles exactly one resource type
- Write self-documenting code with clear naming; follow established naming conventions evident in the codebase

### Security

- Never store secrets in Terraform files or state; use managed identities instead of passwords/keys
- Use `use_azuread_auth = true` in backend configuration (as established in `versions.tf`)
- Use `storage_use_azuread = true` in the AzureRM provider (as established in `providers.tf`)
- Set `resource_provider_registrations = "none"` and `skip_provider_registration = true` to follow least-privilege principles
- Use resource group locks (`resource_group_lock_enabled = true` by default) to prevent accidental deletion
- Apply `precondition` lifecycle blocks in `terraform_data` resources for input validation (see `data_remote_state.tf`)
- Never hardcode subscription IDs, tenant IDs, or other sensitive identifiers
- Mark sensitive variables with `sensitive = true`; never output sensitive data without marking the output sensitive
- OWASP Top 10 compliance; never disable security features for convenience
- Use `min_tls_version = "TLS1_2"` for all storage accounts and services that support it

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
├── main.tf                    # Resource groups + primary module(s)
├── naming.tf                  # Azure naming module (for_each with naming_instances)
├── providers.tf               # Provider configuration
├── regions.tf                 # Azure regions module
├── versions.tf                # Terraform and provider versions + backend
├── outputs.tf                 # All outputs
├── variables.tf               # Core variables (company, subscription_id, tags, locks, telemetry)
├── variables_*.tf             # Grouped variables (hubs, regions, remote_state, features)
├── locals_*.tf                # Grouped locals (naming, config, resource_groups, addressing)
├── data_providers.tf          # Data sources (azurerm_client_config)
├── data_remote_state.tf       # Remote state + validation preconditions
├── *_diagnostics.tf           # Diagnostic settings by resource type
├── *_alerts.tf                # Metric alerts by resource type
├── tests/                     # Unit tests (.tftest.hcl)
├── examples/                  # Example tfvars (basic/, full/)
├── .terraform-docs.yml        # terraform-docs configuration
└── _header.md                 # Custom header for terraform-docs README generation
```

### Provider Configuration Pattern

Connectivity modules use this exact pattern:

```hcl
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
```

Management module adds the ALZ provider and explicit `subscription_id` on both providers:

```hcl
provider "alz" {
  library_overwrite_enabled = true
  library_references = [
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

provider "azapi" {
  skip_provider_registration = true
  subscription_id            = var.management_subscription_id
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  resource_provider_registrations = "none"
  storage_use_azuread             = true
  subscription_id                 = var.management_subscription_id
}
```

### Backend Configuration Pattern

All modules use Azure AD authentication for the backend:

```hcl
terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
}
```

### Naming Module Pattern (from actual code)

```hcl
resource "random_string" "random_seed" {
  length  = 3
  special = false
  upper   = false
  numeric = false
}

module "naming" {
  source   = "Azure/naming/azurerm"
  version  = "0.4.3"
  for_each = local.naming_instances

  unique-seed = random_string.random_seed.result

  suffix = [
    substr(var.company, 0, 3),
    module.azure_regions.regions_by_name[each.value.region].geo_code,
    terraform.workspace,
    each.value.component,
    "001"
  ]
}
```

### Naming Instances and Extended Naming Pattern (from actual code)

```hcl
locals {
  # Naming instances for module.naming - one per component per region
  naming_instances = merge(
    { for region in keys(local.enabled_hubs) : "hub-${region}" => { component = "hub", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-fw-${region}" => { component = "hub-fw", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-bas-${region}" => { component = "hub-bas", region = region } },
    # ... more instances per feature
  )

  # CAF prefixes for resource types not in Azure/naming module
  caf_prefixes = {
    ampls       = "ampls"
    bastion     = "bas"
    firewall    = "afw"
    route_table = "rt"
  }

  # Extended naming - replace rg- prefix with CAF prefix for unlisted types
  naming_extended = {
    for key, instance in local.naming_instances : key => merge(
      module.naming[key],
      {
        firewall = {
          name = replace(module.naming[key].resource_group.name, "/^rg-/", "${local.caf_prefixes.firewall}-")
        }
        # ... more extended names
      }
    )
  }

  # Hub resource names with coalesce for name overrides
  hub_names = {
    for region, hub in local.enabled_hubs : region => {
      resource_group  = coalesce(hub.name_overrides.resource_group, module.naming["hub-${region}"].resource_group.name)
      virtual_network = coalesce(hub.name_overrides.virtual_network, module.naming["hub-${region}"].virtual_network.name)
      firewall        = coalesce(hub.name_overrides.firewall, local.naming_extended["hub-${region}"].firewall.name)
    }
  }
}
```

### Regions Module Pattern (from actual code)

```hcl
module "azure_regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.3"

  enable_telemetry = var.enable_avm_telemetry
  geography_filter = var.region_geography
  is_recommended   = var.region_recommended_filter
}
```

### Hub Filtering and Indexing Pattern (from actual code)

```hcl
locals {
  hub_keys_sorted    = sort(keys(var.hubs))
  hub_indices        = { for idx, key in local.hub_keys_sorted : key => idx }
  enabled_hubs       = { for k, v in var.hubs : k => v if v.enabled }
  primary_hub_region = local.hub_keys_sorted[0]
}
```

### Resource Groups Pattern (from actual code)

```hcl
locals {
  hub_resource_groups = {
    for region, hub in local.enabled_hubs : "hub-${region}" => {
      name     = local.hub_names[region].resource_group
      location = region
      tags     = merge(var.tags, hub.tags)
    }
  }

  # Conditional resource groups for optional features
  dns_resource_group = anytrue([for h in local.enabled_hubs : h.features.private_dns_zones]) ? {
    dns = {
      name     = module.naming["hub-dns"].resource_group.name
      location = local.primary_hub_region
      tags     = var.tags
    }
  } : {}

  all_resource_groups = merge(
    local.hub_resource_groups,
    local.dns_resource_group,
  )
}

module "resource_groups" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  for_each = local.all_resource_groups

  enable_telemetry = var.enable_avm_telemetry
  location         = each.value.location
  lock = var.resource_group_lock_enabled ? {
    kind = "CanNotDelete"
    name = "CanNotDelete"
  } : null
  name = each.value.name
  tags = each.value.tags
}
```

### Remote State and Validation Pattern (from actual code)

```hcl
data "terraform_remote_state" "management" {
  count = var.management_remote_state.enabled ? 1 : 0

  backend   = var.management_remote_state.backend
  workspace = coalesce(var.management_remote_state.workspace, terraform.workspace)

  config = {
    storage_account_name = var.management_remote_state.storage_account_name
    container_name       = var.management_remote_state.container_name
    key                  = var.management_remote_state.key
    use_azuread_auth     = var.management_remote_state.use_azuread_auth
  }
}

locals {
  management_outputs = var.management_remote_state.enabled ? data.terraform_remote_state.management[0].outputs : {}

  # Safe access with try/coalesce chain for optional remote outputs
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
      error_message = "AMPLS requires log_analytics_workspace_id. Set it directly or enable management_remote_state."
    }
  }
}
```

### Diagnostic Settings Pattern (from actual code)

```hcl
# Azure Firewall Diagnostic Settings
# Reference: https://learn.microsoft.com/en-us/azure/firewall/firewall-diagnostics

locals {
  firewalls_with_diagnostics = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.firewall && local.log_analytics_workspace_id != null
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  for_each = local.firewalls_with_diagnostics

  name                           = "diag-afw-${each.key}"
  target_resource_id             = module.hub_and_spoke_vnet.firewall_resource_ids[each.key]
  log_analytics_workspace_id     = local.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log { category = "AZFWApplicationRule" }
  enabled_log { category = "AZFWNetworkRule" }
  enabled_log { category = "AZFWNatRule" }
  enabled_log { category = "AZFWThreatIntel" }
  enabled_log { category = "AZFWIdpsSignature" }
  enabled_log { category = "AZFWDnsQuery" }
  enabled_log { category = "AZFWFatFlow" }
  enabled_log { category = "AZFWFlowTrace" }

  enabled_metric { category = "AllMetrics" }
}
```

### Metric Alerts Pattern (from actual code)

```hcl
locals {
  firewalls_with_alerts = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.firewall && local.log_analytics_workspace_id != null
  }
}

# Firewall health degradation alert (severity 1)
resource "azurerm_monitor_metric_alert" "firewall_health" {
  for_each = local.firewalls_with_alerts

  name                = "alert-firewall-health-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.hub_and_spoke_vnet.firewall_resource_ids[each.key]]
  description         = "Alert when Azure Firewall health degrades in ${each.key}"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/azureFirewalls"
    metric_name      = "FirewallHealth"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  tags = var.tags
}

# SNAT port exhaustion alert (severity 2)
resource "azurerm_monitor_metric_alert" "firewall_snat_exhaustion" {
  for_each = local.firewalls_with_alerts

  name                = "alert-firewall-snat-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.hub_and_spoke_vnet.firewall_resource_ids[each.key]]
  description         = "Alert when SNAT port utilization exceeds 80% in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/azureFirewalls"
    metric_name      = "SNATPortUtilization"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  tags = var.tags
}
```

### Output Patterns (from actual code)

```hcl
# Simple computed value
output "hub_regions" {
  description = "Regions where hubs are deployed."
  value       = keys(local.enabled_hubs)
}

# Diagnostic settings - keyed by region
output "firewall_diagnostic_setting_ids" {
  description = "Diagnostic setting IDs for firewall."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.firewall : k => v.id }
}

# Alerts - nested by alert type then region
output "firewall_alert_ids" {
  description = "Firewall metric alert IDs, keyed by region and alert type."
  value = {
    health     = { for k, v in azurerm_monitor_metric_alert.firewall_health : k => v.id }
    snat       = { for k, v in azurerm_monitor_metric_alert.firewall_snat_exhaustion : k => v.id }
    throughput = { for k, v in azurerm_monitor_metric_alert.firewall_throughput : k => v.id }
  }
}

# Count-based modules (management) - use try for safety
output "log_analytics_workspace_id" {
  description = "The resource ID of the log analytics workspace."
  value       = try(module.management_resources[0].log_analytics_workspace.id, null)
}
```

### Variable Patterns (from actual code)

```hcl
# Core variable with regex validation
variable "connectivity_subscription_id" {
  type        = string
  description = "Subscription ID for connectivity resources (hub networks, firewalls, DNS)."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.connectivity_subscription_id))
    error_message = "Subscription ID must be a valid GUID."
  }
}

# Simple toggle with informative description
variable "enable_avm_telemetry" {
  type        = bool
  description = "Enable telemetry collection for Azure Verified Modules. See https://aka.ms/avm/telemetryinfo."
  default     = false
}

# Feature variable with nested object, optional fields, and defaults
variable "flow_logs" {
  type = object({
    enabled                   = optional(bool, false)
    retention_days            = optional(number, 90)
    traffic_analytics_enabled = optional(bool, false)
    storage = optional(object({
      create                      = optional(bool, true)
      external_storage_account_id = optional(string, null)
      access_tier                 = optional(string, "Hot")
      account_replication_type    = optional(string, "GRS")
      min_tls_version             = optional(string, "TLS1_2")
      public_network_access       = optional(bool, false)
      network_rules = optional(object({
        ip_rules                   = optional(list(string), [])
        virtual_network_subnet_ids = optional(list(string), [])
      }), {})
    }), {})
  })
  default     = {}
  description = "Flow logs configuration..."

  validation {
    condition     = var.flow_logs.retention_days >= 90 && var.flow_logs.retention_days <= 365
    error_message = "retention_days must be between 90 and 365 (security compliance requirement)."
  }
}

# Complex map(object) variable with multiple validations
variable "hubs" {
  type = map(object({
    enabled       = optional(bool, true)
    address_space = optional(string)
    features = optional(object({
      firewall           = optional(bool, true)
      firewall_sku       = optional(string, "Standard")
      bastion            = optional(bool, false)
      vpn_gateway        = optional(bool, false)
      private_dns_zones  = optional(bool, true)
      availability_zones = optional(list(string))
    }), {})
    name_overrides = optional(object({
      resource_group  = optional(string)
      virtual_network = optional(string)
      firewall        = optional(string)
    }), {})
    tags = optional(map(string), {})
  }))
  description = "Hub virtual network configurations keyed by Azure region name."

  validation {
    condition     = length(var.hubs) > 0
    error_message = "At least one hub must be defined."
  }
}

# Remote state variable with conditional validation
variable "management_remote_state" {
  description = "Configuration for fetching management landing zone outputs via remote state."
  type = object({
    enabled              = optional(bool, true)
    backend              = optional(string, "azurerm")
    workspace            = optional(string, null)
    storage_account_name = optional(string, null)
    container_name       = optional(string, "tfstate")
    key                  = optional(string, "management.tfstate")
    use_azuread_auth     = optional(bool, true)
  })
  default = {}

  validation {
    condition = (
      !var.management_remote_state.enabled ||
      var.management_remote_state.storage_account_name != null
    )
    error_message = "storage_account_name is required when management_remote_state is enabled."
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
eirctl docs              # Generate terraform-docs for all modules
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

### Test File Pattern (from actual code)

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
          { name = "uksouth", displayName = "UK South", metadata = { regionType = "Physical", regionCategory = "Recommended", geography = "United Kingdom", geographyGroup = "Europe", physicalLocation = "London", pairedRegion = [{ name = "ukwest" }] } },
          { name = "ukwest", displayName = "UK West", metadata = { regionType = "Physical", regionCategory = "Other", geography = "United Kingdom", geographyGroup = "Europe", physicalLocation = "Cardiff", pairedRegion = [{ name = "uksouth" }] } }
        ]
      }
    }
  }
}

mock_provider "random" {}

override_module {
  target = module.azure_regions
  outputs = {
    regions_by_name = {
      uksouth = { geo_code = "uks", name = "uksouth", display_name = "UK South", zones = ["1", "2", "3"] }
      ukwest  = { geo_code = "ukw", name = "ukwest", display_name = "UK West", zones = ["1", "2", "3"] }
    }
  }
}

override_data {
  target = data.terraform_remote_state.management
  values = { outputs = {} }
}

test {
  parallel = true
}

# =============================================================================
# Section Header
# =============================================================================

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

- Root README: Auto-generated via terraform-docs
- Config: `.terraform-docs.yml` in `deploy/terraform/` controls output format (markdown, sorted by required, inject mode)
- Run: `eirctl docs` from module root
- terraform-docs generates content between `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` markers

## ALZ Library Structure

Located at `deploy/terraform/lib/` (management only):

- `architecture_definitions/` — Management group hierarchy (e.g., `alz_custom.alz_architecture_definition.yaml`)
- `archetype_definitions/` — Policy overrides per management group (e.g., `root_custom.alz_archetype_override.yaml`)

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

### Adding a New Landing Zone Module

1. Create `src/<module-name>/` with `eirctl.env`, `eirctl.yaml`, `yamllint.conf`, `README.md`
2. Create `src/<module-name>/deploy/terraform/` with the standard file organization
3. Follow the management module pattern for count-based conditional modules, or connectivity pattern for always-on with feature toggles
4. Wire up remote state consumption from upstream modules using `data_remote_state.tf`
5. Expose outputs needed by downstream modules
6. Create documentation in `docs/readme/<module-name>/` following existing AsciiDoc structure
7. Create tests in `deploy/terraform/tests/`
8. Create examples in `deploy/terraform/examples/`

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

## Codebase Scanning Instructions

When context files don't provide specific guidance:

1. Identify similar files to the one being modified or created
2. Analyze patterns for naming conventions, code organization, error handling, and testing style
3. Follow the most consistent patterns found in the codebase
4. When conflicting patterns exist, prioritize patterns in connectivity modules (most recently updated)
5. Never introduce patterns not found in the existing codebase

## General Best Practices

- Follow `snake_case` for all Terraform identifiers (variables, locals, resources, outputs)
- Use `for_each` with maps for multi-region resources; use `count` only for 0-or-1 conditional modules
- Prefer implicit dependencies; use `depends_on` only when the dependency cannot be expressed through references (e.g., module-level dependencies)
- Place `for_each`/`count` first in resource blocks, then core attributes, then nested blocks
- Use `terraform fmt` for consistent formatting (enforced by CI)
- All variables must have `type` and `description`; use `optional()` with defaults for nested objects
- All outputs must have `description`
- Include a Microsoft Learn reference URL as a comment header in diagnostic and alert files
- Use CAF naming conventions via the `Azure/naming/azurerm` module
- Validate inputs at the variable level using `validation` blocks with clear error messages
- Always pass `enable_telemetry = var.enable_avm_telemetry` to AVM modules
- Always pass `tags = merge(var.tags, each.value.tags)` for per-resource tag merging where applicable
- Resource group locks default to enabled via `var.resource_group_lock_enabled`
- Use `coalesce()` for name override chains, `try(..., null)` for safe access to optional values
- Use deterministic iteration: sort keys, use indices for stable address allocation
- Comment severity before each alert resource: `# [description] (severity N)`
- Never introduce patterns not found in the existing codebase
