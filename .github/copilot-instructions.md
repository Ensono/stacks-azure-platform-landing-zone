# Copilot Instructions for Stacks Azure Platform Landing Zone

## Project Overview

This repository provides starter modules for deploying Azure Landing Zones using **Azure Verified Modules (AVM)**. The primary implementation is the Management Landing Zone template at `templates/management_landing_zone/`.

These modules are imported into landing zone repositories created by the bootstrap module. CI/CD pipelines are managed by the bootstrap, not in this repo.

## Subscription Requirements

Different deployment scenarios require different subscriptions:

| Scenario | Required Subscriptions |
|----------|----------------------|
| Management resources only | `management` |
| Full ALZ with management groups | `connectivity`, `identity`, `management` |

Subscription IDs are passed via `subscription_ids` map in `terraform.tfvars`. See `deploy/terraform/examples/` for configuration examples including the Ensono tricode naming convention.

## Architecture

### Module Dependency Chain

```
config_templating → management_resources → management_groups
```

1. **config_templating** - Processes configuration templates, generates location short codes, and custom replacements for policy values
2. **management_resources** - Deploys Log Analytics Workspace, Data Collection Rules, and managed identities (wraps [Azure/avm-ptn-alz-management](https://registry.terraform.io/modules/Azure/avm-ptn-alz-management/azurerm/latest))
3. **management_groups** - Deploys management group hierarchy and policies (wraps [Azure/avm-ptn-alz](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest))

### Key Design Patterns

- **Conditional modules via `count`**: Root modules use `count = var.*_enabled ? 1 : 0`. Access outputs with `module.name[0].output` and wrap in `try(..., null)` for safety
- **Template string replacements**: Use `$${variable_name}` syntax in tfvars for dynamic values (e.g., `$${starter_location_01}`, `$${subscription_id_management}`)
- **Naming conventions**: Supports `caf_azure` (default) or `stacks_foundation_azure` via `var.naming_convention`

## Developer Workflows

### Task Runner (eirctl)

Run from `templates/management_landing_zone/`:

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

Located at `deploy/terraform/lib/`:

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
