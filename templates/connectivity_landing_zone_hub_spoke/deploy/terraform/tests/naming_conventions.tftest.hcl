# Test: Hub Naming Conventions
# Validates that generated resource names follow CAF patterns

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

variables {
  connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"
  hub_network_address_prefix   = "10.0.0.0/8"
  company_name                 = "ens"
  hubs                         = { uksouth = { enabled = true } }
  ensono_tags                  = { enabled = false }
}

run "resource_names_follow_caf_conventions" {
  command = plan

  assert {
    condition     = startswith(local.hub_names["uksouth"].resource_group, "rg-")
    error_message = "Resource group name should start with 'rg-' prefix."
  }

  assert {
    condition     = can(regex("rg-ens-", local.hub_names["uksouth"].resource_group))
    error_message = "Resource group name should contain company name."
  }

  assert {
    condition     = startswith(local.hub_names["uksouth"].virtual_network, "vnet-")
    error_message = "Virtual network name should start with 'vnet-' prefix."
  }

  assert {
    condition     = startswith(local.hub_names["uksouth"].firewall, "fw-")
    error_message = "Firewall name should start with 'fw-' prefix."
  }

  assert {
    condition     = startswith(local.hub_names["uksouth"].bastion, "bas-")
    error_message = "Bastion name should start with 'bas-' prefix."
  }

  assert {
    condition     = startswith(local.hub_names["uksouth"].route_table_firewall, "route-")
    error_message = "Route table name should start with 'route-' prefix."
  }

  assert {
    condition     = startswith(local.hub_names["uksouth"].route_table_user, "route-")
    error_message = "User route table name should start with 'route-' prefix."
  }
}
