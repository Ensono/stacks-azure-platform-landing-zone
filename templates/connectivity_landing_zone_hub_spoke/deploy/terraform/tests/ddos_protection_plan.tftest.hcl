# Test: DDoS Protection Plan Configuration
# Validates DDoS Protection Plan default behavior and configuration options

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
  company_name                 = "ens"
  connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"
  hub_network_address_prefix   = "10.0.0.0/8"
  ensono_tags                  = { enabled = false }
  azure_monitor_private_link   = { enabled = false }

  hubs = {
    uksouth = {
      enabled = true
    }
  }
}

run "ddos_disabled_by_default" {
  command = plan

  assert {
    condition     = var.ddos_protection_plan.enabled == false
    error_message = "DDoS Protection Plan should be disabled by default."
  }

  assert {
    condition     = local.hub_and_spoke_settings.enabled_resources.ddos_protection_plan == false
    error_message = "DDoS Protection Plan should be disabled in hub settings when not enabled."
  }
}

run "ddos_no_resource_group_when_disabled" {
  command = plan

  assert {
    condition     = !contains(keys(local.ddos_resource_group), "ddos")
    error_message = "DDoS resource group should not exist when DDoS is disabled."
  }
}

run "ddos_enabled_creates_resource_group" {
  command = plan

  variables {
    ddos_protection_plan = {
      enabled = true
    }
  }

  assert {
    condition     = var.ddos_protection_plan.enabled == true
    error_message = "DDoS Protection Plan should be enabled when set to true."
  }

  assert {
    condition     = contains(keys(local.ddos_resource_group), "ddos")
    error_message = "DDoS resource group should exist when DDoS is enabled."
  }

  assert {
    condition     = local.ddos_resource_group["ddos"].location == "uksouth"
    error_message = "DDoS resource group should be in the primary hub region."
  }
}

run "ddos_enabled_configures_hub_settings" {
  command = plan

  variables {
    ddos_protection_plan = {
      enabled = true
    }
  }

  assert {
    condition     = local.hub_and_spoke_settings.enabled_resources.ddos_protection_plan == true
    error_message = "DDoS Protection Plan should be enabled in hub settings."
  }

  assert {
    condition     = local.hub_and_spoke_settings.ddos_protection_plan.location == "uksouth"
    error_message = "DDoS Protection Plan should be deployed to primary hub region."
  }

  assert {
    condition     = can(regex("^ddospp-", local.hub_and_spoke_settings.ddos_protection_plan.name))
    error_message = "DDoS Protection Plan name should follow CAF naming convention (ddospp- prefix)."
  }
}

run "ddos_accepts_custom_name" {
  command = plan

  variables {
    ddos_protection_plan = {
      enabled = true
      name    = "custom-ddos-plan"
    }
  }

  assert {
    condition     = local.hub_and_spoke_settings.ddos_protection_plan.name == "custom-ddos-plan"
    error_message = "DDoS Protection Plan should use custom name when provided."
  }
}
