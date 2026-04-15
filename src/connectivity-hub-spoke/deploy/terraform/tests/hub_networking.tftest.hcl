# Test: Hub Networking
# Validates address space allocation, subnet calculations, multi-hub addressing, and mesh peering

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

# Variables loaded from terraform.tfvars

test {
  parallel = true
}

# =============================================================================
# Single Hub - Default Configuration
# Tests address space, subnet CIDRs, mesh peering (disabled for single hub)
# =============================================================================

run "single_hub_networking_defaults" {
  command   = plan
  state_key = "single_hub"

  # Address space from 10.0.0.0/8 base prefix
  assert {
    condition     = local.hub_addresses["uksouth"].hub_address_space == "10.0.0.0/16"
    error_message = "Default hub address space should be 10.0.0.0/16."
  }

  # Subnet CIDRs are valid
  assert {
    condition     = can(cidrhost(local.hub_subnets["uksouth"].firewall, 0)) && can(cidrhost(local.hub_subnets["uksouth"].bastion, 0)) && can(cidrhost(local.hub_subnets["uksouth"].gateway, 0))
    error_message = "All subnet CIDRs must be valid."
  }

  # Azure minimum sizes: Firewall /26, Bastion /26, Gateway /27
  assert {
    condition     = tonumber(split("/", local.hub_subnets["uksouth"].firewall)[1]) <= 26 && tonumber(split("/", local.hub_subnets["uksouth"].bastion)[1]) <= 26 && tonumber(split("/", local.hub_subnets["uksouth"].gateway)[1]) <= 27
    error_message = "Subnets must meet Azure minimum size requirements."
  }

  # Single hub disables mesh peering
  assert {
    condition     = local.hub_virtual_networks["uksouth"].hub_virtual_network.mesh_peering_enabled == false
    error_message = "Mesh peering should be disabled for single hub."
  }

  # Default subnet exists
  assert {
    condition     = contains(keys(local.hub_virtual_networks["uksouth"].hub_virtual_network.subnets), "private_endpoints")
    error_message = "Default private endpoints subnet should exist."
  }
}

# =============================================================================
# Multi-Hub Configuration
# Tests unique addressing and mesh peering enabled
# =============================================================================

run "multi_hub_networking" {
  command   = plan
  state_key = "multi_hub"

  variables {
    hubs = {
      uksouth = { enabled = true }
      ukwest  = { enabled = true }
    }
  }

  # Unique address spaces per hub
  assert {
    condition     = local.hub_addresses["uksouth"].hub_address_space != local.hub_addresses["ukwest"].hub_address_space
    error_message = "Hub address spaces must be unique per region."
  }

  # Deterministic hub indices
  assert {
    condition     = local.hub_indices["uksouth"] == 0 && local.hub_indices["ukwest"] == 1
    error_message = "Hub indices should be deterministic (alphabetical order)."
  }

  # Mesh peering enabled for multi-hub
  assert {
    condition     = local.hub_virtual_networks["uksouth"].hub_virtual_network.mesh_peering_enabled == true && local.hub_virtual_networks["ukwest"].hub_virtual_network.mesh_peering_enabled == true
    error_message = "Mesh peering should be enabled for all hubs in multi-hub."
  }
}

# =============================================================================
# Custom Address Space Override
# =============================================================================

run "custom_address_space" {
  command   = plan
  state_key = "custom_addr"

  variables {
    hubs = {
      uksouth = {
        enabled       = true
        address_space = "172.16.0.0/16"
      }
    }
  }

  assert {
    condition     = local.hub_addresses["uksouth"].hub_address_space == "172.16.0.0/16"
    error_message = "Hub address space should use custom override."
  }

  assert {
    condition     = local.hub_subnets["uksouth"].vnet_address_space == "172.16.0.0/22"
    error_message = "VNet address space should be derived from custom hub address space."
  }
}

# =============================================================================
# Custom Subnets
# =============================================================================

run "custom_subnets_merged" {
  command   = plan
  state_key = "custom_subnets"

  variables {
    hubs = {
      uksouth = {
        enabled = true
        custom_subnets = {
          management = {
            name             = "snet-management"
            address_prefixes = ["10.0.4.0/24"]
          }
        }
      }
    }
  }

  assert {
    condition     = contains(keys(local.hub_virtual_networks["uksouth"].hub_virtual_network.subnets), "management") && contains(keys(local.hub_virtual_networks["uksouth"].hub_virtual_network.subnets), "private_endpoints")
    error_message = "Custom subnets should be merged with defaults."
  }
}
