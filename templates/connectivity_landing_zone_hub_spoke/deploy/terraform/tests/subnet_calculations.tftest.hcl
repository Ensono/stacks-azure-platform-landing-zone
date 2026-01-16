# Test: Subnet CIDR Calculations
# Validates that automatically calculated subnets are valid and correctly sized

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
  hubs                         = { uksouth = { enabled = true } }
  ensono_tags                  = { enabled = false }
}

run "subnet_cidrs_valid_and_correctly_sized" {
  command = plan

  # All subnet CIDRs are valid
  assert {
    condition     = can(cidrhost(local.hub_subnets["uksouth"].firewall, 0))
    error_message = "Firewall subnet CIDR is invalid."
  }

  assert {
    condition     = can(cidrhost(local.hub_subnets["uksouth"].bastion, 0))
    error_message = "Bastion subnet CIDR is invalid."
  }

  assert {
    condition     = can(cidrhost(local.hub_subnets["uksouth"].gateway, 0))
    error_message = "Gateway subnet CIDR is invalid."
  }

  assert {
    condition     = can(cidrhost(local.hub_subnets["uksouth"].dns_resolver, 0))
    error_message = "DNS resolver subnet CIDR is invalid."
  }

  assert {
    condition     = can(cidrhost(local.hub_subnets["uksouth"].private_endpoints, 0))
    error_message = "Private endpoints subnet CIDR is invalid."
  }

  # Azure Firewall requires /26, Bastion requires /26, Gateway requires /27, DNS Resolver requires /28
  assert {
    condition     = tonumber(split("/", local.hub_subnets["uksouth"].firewall)[1]) <= 26
    error_message = "Firewall subnet must be /26 or larger."
  }

  assert {
    condition     = tonumber(split("/", local.hub_subnets["uksouth"].bastion)[1]) <= 26
    error_message = "Bastion subnet must be /26 or larger."
  }

  assert {
    condition     = tonumber(split("/", local.hub_subnets["uksouth"].gateway)[1]) <= 27
    error_message = "Gateway subnet must be /27 or larger."
  }

  assert {
    condition     = tonumber(split("/", local.hub_subnets["uksouth"].dns_resolver)[1]) <= 28
    error_message = "DNS resolver subnet must be /28 or larger."
  }
}
