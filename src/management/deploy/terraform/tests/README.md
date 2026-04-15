# Unit Tests for Management

This directory contains unit tests for the management module.

## Test Structure

Tests use Terraform's built-in test framework (`.tftest.hcl` files) with mock providers
and module overrides to validate configuration logic without deploying actual Azure resources.

### Files

| File | Purpose |
| ---- | ------- |
| `terraform.tfvars` | Default variable values auto-loaded by all tests |
| `locals_safe_defaults.tftest.hcl` | Ensures locals don't error when features are disabled; resource groups toggle |
| `monitoring_alerts.tftest.hcl` | Auto-enable logic, GB-to-bytes conversion, explicit disable override |
| `naming.tftest.hcl` | CAF naming prefixes and azure_regions geo_code contract |
| `policy_assignments.tftest.hcl` | Defender plan toggles, sub-features, email/export propagation, DNS enforcement |
| `subscription_placement.tftest.hcl` | All subscriptions, skip mode, optional security subscription |

## Running Tests

```bash
# Run all tests
terraform test

# Run a specific test file
terraform test -filter=tests/naming.tftest.hcl

# Run with verbose output
terraform test -verbose
```

## Default Variables

The `terraform.tfvars` file sets only the required variables (those without defaults):
`company`, `region`, and `management_subscription_id`.

Optional variables (`connectivity_subscription_id`, `identity_subscription_id`, etc.) are
left at their defaults (`null` / `false`) and set explicitly in test `variables` blocks
where needed. This keeps the tfvars minimal and makes each test self-documenting.

Resource creation is prevented at the module level through `override_module` directives in
individual test files, which stub dependencies and control what resources are instantiated.

## Mock Providers and Module Overrides

AVM modules depend on the `azure/modtm` provider for telemetry, which cannot be resolved
via `mock_provider` (it defaults to the `hashicorp/` namespace). Instead, tests use
`override_module` to stub AVM modules that carry this dependency.

Copy this block to the top of new test files:

```hcl
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
          { name = "uksouth", displayName = "UK South", metadata = { regionType = "Physical", regionCategory = "Recommended", geography = "United Kingdom", geographyGroup = "Europe", physicalLocation = "London", pairedRegion = [{ name = "ukwest" }] } }
        ]
      }
    }
  }
}

mock_provider "alz" {}

# Override AVM modules that depend on azure/modtm provider
override_module {
  target = module.azure_regions
  outputs = {
    regions_by_name = {
      uksouth = { name = "uksouth", display_name = "UK South", geo_code = "uks" }
    }
    regions                         = {}
    regions_by_display_name         = {}
    regions_by_geography            = {}
    regions_by_geography_group      = {}
    regions_by_name_or_display_name = {}
    valid_region_display_names      = []
    valid_region_names              = ["uksouth"]
    valid_region_names_or_display_names = []
  }
}

override_module {
  target = module.resource_groups
}
```

The `module.naming` (uses `hashicorp/random` only) is **not** overridden so its CAF naming logic executes normally.

## Writing New Tests

1. Copy mock providers and `override_module` blocks from an existing test file
2. Rely on `terraform.tfvars` for defaults — only override what you need to test
3. Use `command = plan` for fast unit tests that validate logic
4. Keep tests focused on a single concern
5. Use unique `state_key` values per run block to enable `parallel = true`
