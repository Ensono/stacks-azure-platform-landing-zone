# Test configuration for management_landing_zone
# These values are used by terraform test
#
# Note: Tests disable management_resources and management_groups by default
# to allow testing of naming, tags, and configuration logic without
# requiring Azure API calls or complex object instantiation.

company_name = "ensono"
location     = "uksouth"

management_subscription_id   = "00000000-0000-0000-0000-000000000000"
connectivity_subscription_id = "11111111-1111-1111-1111-111111111111"
identity_subscription_id     = "22222222-2222-2222-2222-222222222222"
security_subscription_id     = "33333333-3333-3333-3333-333333333333"

# Disable resources by default for unit tests
# Individual tests can override with variables block
management_resources_enabled = false
management_groups_enabled    = false
