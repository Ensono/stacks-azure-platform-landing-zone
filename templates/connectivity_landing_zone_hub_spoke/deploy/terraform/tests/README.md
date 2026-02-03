# Unit Tests for Connectivity Landing Zone Hub-Spoke

This directory contains unit tests for the connectivity landing zone hub-spoke module.

## Test Structure

Tests use Terraform's built-in test framework (`.tftest.hcl` files) with mock providers
to validate configuration logic without deploying actual Azure resources.

### Files

| File | Purpose |
|------|---------|
| `terraform.tfvars` | Default variable values auto-loaded by all tests |
| `hub_networking.tftest.hcl` | Address space, subnets, multi-hub, mesh peering |
| `hub_resources.tftest.hcl` | Features, gateways, DNS, DDoS, AMPLS, firewall, Network Watcher, flow logs, NSG |

## Running Tests

```bash
# Run all tests (~3 minutes)
terraform test

# Run a specific test file (~1 minute)
terraform test -filter=tests/hub_networking.tftest.hcl

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
    hubs = { uksouth = { enabled = true, features = { firewall = false } } }
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

mock_provider "local" {}
```

## Writing New Tests

1. Copy mock providers from an existing test file
2. Rely on `terraform.tfvars` for defaults - only override what you need to test
3. Use `command = plan` for fast unit tests that validate logic
4. Keep tests focused on a single concern
