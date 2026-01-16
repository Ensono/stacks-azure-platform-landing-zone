# Test: Mesh Peering Configuration
# Validates mesh peering is correctly enabled for multi-hub scenarios

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
}

run "single_hub_disables_mesh_peering" {
  command = plan

  variables {
    hubs = { uksouth = { enabled = true } }
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].hub_virtual_network.mesh_peering_enabled == false
    error_message = "Mesh peering should be disabled for single hub."
  }
}

run "multi_hub_enables_mesh_peering" {
  command = plan

  variables {
    hubs = {
      uksouth = { enabled = true }
      ukwest  = { enabled = true }
    }
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].hub_virtual_network.mesh_peering_enabled == true
    error_message = "Mesh peering should be enabled for multi-hub (uksouth)."
  }

  assert {
    condition     = local.hub_virtual_networks["ukwest"].hub_virtual_network.mesh_peering_enabled == true
    error_message = "Mesh peering should be enabled for multi-hub (ukwest)."
  }
}

run "disabled_hub_does_not_affect_mesh_peering" {
  command = plan

  variables {
    hubs = {
      uksouth = { enabled = true }
      ukwest  = { enabled = false }
    }
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].hub_virtual_network.mesh_peering_enabled == false
    error_message = "Mesh peering should be disabled when only one hub is enabled."
  }
}
