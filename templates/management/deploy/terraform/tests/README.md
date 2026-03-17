# Unit Tests for Management Landing Zone

This directory contains unit tests for the management landing zone module.

## Test Structure

Tests use Terraform's built-in test framework (`.tftest.hcl` files) with mock providers
to validate configuration logic without deploying actual Azure resources.

### Files

| File | Purpose |
| ---- | ------- |
| `terraform.tfvars` | Default variable values auto-loaded by all tests |
| `locals_safe_defaults.tftest.hcl` | Ensures locals don't error when features are disabled |
| `monitoring_alerts.tftest.hcl` | Auto-enable logic for health monitoring alerts |
| `naming.tftest.hcl` | CAF naming module integration and azure_regions module |

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

The `terraform.tfvars` file provides sensible defaults for all required variables.
Individual tests can override specific values in their `variables` blocks.

```hcl
# Example: Override a default in a run block
run "my_test" {
  variables {
    log_analytics = { retention_in_days = 90 }
  }
}
```

## Mock Providers

Terraform tests require mock providers to be defined in **each test file**.
This cannot be centralized due to Terraform's test framework design.

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

mock_provider "azapi" {}
mock_provider "random" {}
mock_provider "modtm" {}
mock_provider "time" {}
mock_provider "alz" {}
```

## Writing New Tests

1. Copy mock providers from an existing test file
2. Rely on `terraform.tfvars` for defaults - only override what you need to test
3. Use `command = plan` for fast unit tests that validate logic
4. Keep tests focused on a single concern
