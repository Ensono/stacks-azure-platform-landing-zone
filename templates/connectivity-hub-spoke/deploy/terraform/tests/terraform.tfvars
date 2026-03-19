# Common test variables for connectivity-hub-spoke tests
# These defaults provide a minimal valid configuration for unit testing

company_name                 = "ens"
connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"
hub_network_address_prefix   = "10.0.0.0/8"

hubs = {
  uksouth = {
    enabled = true
  }
}

management_remote_state = {
  enabled = false
}

azure_monitor_private_link = {
  enabled = false
}
