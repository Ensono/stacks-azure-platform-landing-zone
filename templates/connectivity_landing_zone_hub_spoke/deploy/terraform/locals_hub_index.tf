locals {
  hub_keys_sorted    = sort(keys(var.hubs))
  hub_indices        = { for idx, key in local.hub_keys_sorted : key => idx }
  enabled_hubs       = { for k, v in var.hubs : k => v if v.enabled }
  primary_hub_region = local.hub_keys_sorted[0]
}
