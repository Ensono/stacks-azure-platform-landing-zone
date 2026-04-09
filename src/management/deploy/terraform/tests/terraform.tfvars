# Test configuration for management
# These values are used by terraform test
#
# Only required variables (no default) that are shared across ALL tests.
# Test-specific variables belong in individual .tftest.hcl files.

company = "ensono"
region  = "uksouth"

management_subscription_id = "00000000-0000-0000-0000-000000000000"
