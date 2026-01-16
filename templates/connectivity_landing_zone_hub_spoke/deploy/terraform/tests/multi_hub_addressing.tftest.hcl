# Test: Multi-Hub Address Space Allocation
# Validates that multiple hubs get non-overlapping address spaces

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
  ensono_tags                  = { enabled = false }

  hubs = {
    uksouth = { enabled = true }
    ukwest  = { enabled = true }
  }
}

run "multi_hub_addressing_unique_and_deterministic" {
  command = plan

  # Address spaces are unique
  assert {
    condition     = local.hub_addresses["uksouth"].hub_address_space != local.hub_addresses["ukwest"].hub_address_space
    error_message = "Hub address spaces must be unique per region."
  }

  assert {
    condition     = local.hub_subnets["uksouth"].vnet_address_space != local.hub_subnets["ukwest"].vnet_address_space
    error_message = "VNet address spaces must be unique per hub."
  }

  # Indices are deterministic (sorted keys)
  assert {
    condition     = local.hub_indices["uksouth"] == 0
    error_message = "Hub indices should be deterministic (uksouth first alphabetically)."
  }

  assert {
    condition     = local.hub_indices["ukwest"] == 1
    error_message = "Hub indices should be deterministic (ukwest second alphabetically)."
  }
}
