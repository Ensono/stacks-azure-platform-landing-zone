locals {
  firewalls_with_alerts = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.firewall && local.log_analytics_workspace_id != null
  }
}

# Firewall health degradation alert (severity 1)
resource "azurerm_monitor_metric_alert" "firewall_health" {
  for_each = local.firewalls_with_alerts

  name                = "alert-firewall-health-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.virtual_wan.firewall_resource_ids[each.key]]
  description         = "Alert when Azure Firewall health degrades in ${each.key}"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/azureFirewalls"
    metric_name      = "FirewallHealth"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  tags = var.tags
}

# SNAT port exhaustion alert (severity 2)
resource "azurerm_monitor_metric_alert" "firewall_snat_exhaustion" {
  for_each = local.firewalls_with_alerts

  name                = "alert-firewall-snat-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.virtual_wan.firewall_resource_ids[each.key]]
  description         = "Alert when SNAT port utilization exceeds 80% in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/azureFirewalls"
    metric_name      = "SNATPortUtilization"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  tags = var.tags
}

# High throughput alert (severity 2)
resource "azurerm_monitor_metric_alert" "firewall_throughput" {
  for_each = local.firewalls_with_alerts

  name                = "alert-firewall-throughput-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.virtual_wan.firewall_resource_ids[each.key]]
  description         = "Alert when firewall throughput is high in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/azureFirewalls"
    metric_name      = "Throughput"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 2500000000 # 2.5 Gbps
  }

  tags = var.tags
}

# Firewall latency probe alert (severity 2)
resource "azurerm_monitor_metric_alert" "firewall_latency" {
  for_each = local.firewalls_with_alerts

  name                = "alert-firewall-latency-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.virtual_wan.firewall_resource_ids[each.key]]
  description         = "Alert when firewall latency exceeds 20ms in ${each.key}"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/azureFirewalls"
    metric_name      = "AzureFirewallLatencyProbe"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 20000 # 20ms in microseconds
  }

  tags = var.tags
}
