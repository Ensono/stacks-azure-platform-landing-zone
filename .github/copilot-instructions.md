# Copilot Instructions for Stacks Azure Platform Landing Zone

## Project Overview

This repository provides starter modules for deploying Azure Landing Zones using **Azure Verified Modules (AVM)**. There are two primary templates:

- **Management Landing Zone** (`templates/management_landing_zone/`) - Deploys management groups, policies, and management resources
- **Connectivity Landing Zone Hub-Spoke** (`templates/connectivity_landing_zone_hub_spoke/`) - Deploys hub-and-spoke network topology

These modules are imported into landing zone repositories created by the bootstrap module. CI/CD pipelines are managed by the bootstrap, not in this repo.

## Subscription Requirements

Different deployment scenarios require different subscriptions:

| Template | Required Subscriptions |
|----------|----------------------|
| Management (resources only) | `management` |
| Management (full ALZ with management groups) | `connectivity`, `identity`, `management` |
| Connectivity Hub-Spoke | `connectivity`, `management` |

Subscription IDs are passed via `subscription_ids` map in `terraform.tfvars`. See `deploy/terraform/examples/` in each template for configuration examples.

## Architecture

### Management Landing Zone Module Chain

```
config_templating → management_resources → management_groups
```

1. **config_templating** - Processes configuration templates, generates location short codes, and custom replacements for policy values
2. **management_resources** - Deploys Log Analytics Workspace, Data Collection Rules, and managed identities (wraps [Azure/avm-ptn-alz-management](https://registry.terraform.io/modules/Azure/avm-ptn-alz-management/azurerm/latest))
3. **management_groups** - Deploys management group hierarchy and policies (wraps [Azure/avm-ptn-alz](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest))

### Connectivity Landing Zone Hub-Spoke Module Chain

```
config_templating → resource_groups → hub_and_spoke_vnet
```

1. **config_templating** - Processes configuration templates and generates location short codes
2. **resource_groups** - Deploys resource groups using `for_each` from config (wraps [Azure/avm-res-resources-resourcegroup](https://registry.terraform.io/modules/Azure/avm-res-resources-resourcegroup/azurerm/latest))
3. **hub_and_spoke_vnet** - Deploys hub virtual networks, firewalls, bastion, DNS, and gateways (wraps [Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm/latest))

### Key Design Patterns

- **Conditional modules via `count`** (management_landing_zone): Root modules use `count = var.*_enabled ? 1 : 0`. Access outputs with `module.name[0].output` and wrap in `try(..., null)` for safety
- **Always-on modules** (connectivity_landing_zone_hub_spoke): The hub-and-spoke module always deploys; individual features (firewall, bastion, etc.) are toggled via tfvars settings
- **Template string replacements**: Use `$${variable_name}` syntax in tfvars for dynamic values (e.g., `$${starter_location_01}`, `$${subscription_id_connectivity}`)
- **Naming conventions**: Supports `caf_azure` (default) or `stacks_foundation_azure` via `var.naming_convention`
- **Multi-region support**: Connectivity module supports multiple hubs via `starter_locations` list and per-region settings in tfvars

## Developer Workflows

### Task Runner (eirctl)

Run from the template directory (e.g., `templates/management_landing_zone/` or `templates/connectivity_landing_zone_hub_spoke/`):

```bash
eirctl code:linting        # YAML lint → terraform fmt → validate → tflint
eirctl code:scanning       # Checkov security scan
eirctl code:documentation  # Generate terraform-docs for all modules
eirctl infrastructure:plan # terraform init → plan
eirctl infrastructure:apply
```

### Documentation Generation

- Root README: Auto-generated from `_header.md` via terraform-docs
- Child modules: Each has `_header.md` for custom content; run `terraform-docs` from `deploy/terraform/modules/`
- Config: `.terraform-docs.yml` in each directory controls output

## ALZ Library Structure

Located at `deploy/terraform/lib/` (management_landing_zone only):

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
- `_header.md` - Custom documentation header for terraform-docs
- `*.alz_archetype_override.yaml` - Policy customizations per management group
