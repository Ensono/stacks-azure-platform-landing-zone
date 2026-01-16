locals {
  # Hubs with firewall enabled and Log Analytics available
  firewalls_with_diagnostics = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.firewall && local.log_analytics_workspace_id != null
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  for_each = local.firewalls_with_diagnostics

  name                           = "diag-firewall-${each.key}"
  target_resource_id             = module.hub_and_spoke_vnet.firewall_resource_ids[each.key]
  log_analytics_workspace_id     = local.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  # Structured logs - resource-specific tables
  enabled_log {
    category = "AZFWApplicationRule"
  }

  enabled_log {
    category = "AZFWNetworkRule"
  }

  enabled_log {
    category = "AZFWNatRule"
  }

  enabled_log {
    category = "AZFWThreatIntel"
  }

  enabled_log {
    category = "AZFWIdpsSignature"
  }

  enabled_log {
    category = "AZFWDnsQuery"
  }

  enabled_log {
    category = "AZFWFatFlow"
  }

  enabled_log {
    category = "AZFWFlowTrace"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
