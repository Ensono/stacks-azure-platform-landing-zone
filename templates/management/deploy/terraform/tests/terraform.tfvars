# Test configuration for management
# These values are used by terraform test
#
# Only required variables (no default) are set here.
# Optional variables default to null/false as defined in variables*.tf.
# Individual tests override specific values in their variables blocks.

company_name = "ensono"
location     = "uksouth"

management_subscription_id = "00000000-0000-0000-0000-000000000000"

# Override default (true) to disable for unit tests
management_resources_enabled = false

microsoft_defender_settings = {
  email_security_contact = "test@example.invalid"
}
