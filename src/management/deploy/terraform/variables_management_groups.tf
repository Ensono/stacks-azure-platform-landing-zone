variable "management_groups_enabled" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Enable or disable the deployment of management groups.

When set to `true`, the management group hierarchy will be created and configured according to the `management_group_settings` variable.
When set to `false`, no management groups will be deployed.

DESCRIPTION
}

variable "management_group_settings" {
  type = object({
    architecture_name            = optional(string, "alz_custom")
    parent_management_group_id   = optional(string)
    location                     = optional(string)
    policy_default_values        = optional(any)
    policy_assignments_to_modify = optional(any)
    management_group_hierarchy_settings = optional(object({
      default_management_group_name            = optional(string, "sandbox")
      require_authorization_for_group_creation = optional(bool, true)
      update_existing                          = optional(bool, false)
    }))
    partner_id = optional(string)
    retries = optional(object({
      management_groups = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
        multiplier           = optional(number)
        randomization_factor = optional(number)
      }))
      role_definitions = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
        multiplier           = optional(number)
        randomization_factor = optional(number)
      }))
      role_assignments = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
        multiplier           = optional(number)
        randomization_factor = optional(number)
      }))
      policy_definitions = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
        multiplier           = optional(number)
        randomization_factor = optional(number)
      }))
      policy_set_definitions = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
        multiplier           = optional(number)
        randomization_factor = optional(number)
      }))
      policy_assignments = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
        multiplier           = optional(number)
        randomization_factor = optional(number)
      }))
      policy_role_assignments = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
        multiplier           = optional(number)
        randomization_factor = optional(number)
      }))
      hierarchy_settings = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
        multiplier           = optional(number)
        randomization_factor = optional(number)
      }))
      subscription_placement = optional(object({
        error_message_regex  = optional(list(string))
        interval_seconds     = optional(number)
        max_interval_seconds = optional(number)
        multiplier           = optional(number)
        randomization_factor = optional(number)
      }))
    }), {})
    subscription_placement = optional(map(object({
      subscription_id       = string
      management_group_name = string
    })))
    timeouts = optional(object({
      management_group = optional(object({
        create = optional(string, "60m")
        delete = optional(string, "60m")
        update = optional(string, "60m")
        read   = optional(string, "60m")
      }), {})
      role_definition = optional(object({
        create = optional(string, "60m")
        delete = optional(string, "60m")
        update = optional(string, "60m")
        read   = optional(string, "60m")
      }), {})
      role_assignment = optional(object({
        create = optional(string, "60m")
        delete = optional(string, "60m")
        update = optional(string, "60m")
        read   = optional(string, "60m")
      }), {})
      policy_definition = optional(object({
        create = optional(string, "60m")
        delete = optional(string, "60m")
        update = optional(string, "60m")
        read   = optional(string, "60m")
      }), {})
      policy_set_definition = optional(object({
        create = optional(string, "60m")
        delete = optional(string, "60m")
        update = optional(string, "60m")
        read   = optional(string, "60m")
      }), {})
      policy_assignment = optional(object({
        create = optional(string, "60m")
        delete = optional(string, "60m")
        update = optional(string, "60m")
        read   = optional(string, "60m")
      }), {})
      policy_role_assignment = optional(object({
        create = optional(string, "60m")
        delete = optional(string, "60m")
        update = optional(string, "60m")
        read   = optional(string, "60m")
      }), {})
    }), {})
    dependencies = optional(object({
      management_groups       = optional(any)
      policy_role_assignments = optional(any)
      policy_assignments      = optional(any)
    }))
    override_policy_definition_parameter_assign_permissions_set = optional(set(object({
      definition_name = string
      parameter_name  = string
    })))
    override_policy_definition_parameter_assign_permissions_unset = optional(set(object({
      definition_name = string
      parameter_name  = string
    })))
    management_group_role_assignments = optional(map(object({
      management_group_name                  = string
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string)
      condition_version                      = optional(string)
      delegated_managed_identity_resource_id = optional(string)
      principal_type                         = optional(string)
    })))
    role_assignment_definition_lookup_enabled = optional(bool, true)
    policy_assignment_non_compliance_message_settings = optional(object({
      fallback_message_enabled                 = optional(bool)
      fallback_message                         = optional(string)
      fallback_message_unsupported_assignments = optional(list(string))
      enforcement_mode_placeholder             = optional(string)
      enforced_replacement                     = optional(string)
      not_enforced_replacement                 = optional(string)
    }))
    role_assignment_name_use_random_uuid                             = optional(bool, true)
    subscription_placement_destroy_behavior                          = optional(string, "default")
    subscription_placement_destroy_custom_target_management_group_id = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
The settings for the management groups. This object configures the Azure Landing Zone management group hierarchy, policies, and role assignments.

Properties:
- `architecture_name` - (Optional) The name of the architecture definition to use. Defaults to "alz_custom".
- `parent_management_group_id` - (Optional) The ID/name of the parent management group (e.g., tenant ID or management group name). If omitted, defaults to the tenant root group.
- `location` - (Required) The default Azure region for resources.
- `policy_default_values` - (Optional) A map of default values for policy parameters.
- `policy_assignments_to_modify` - (Optional) Map of policy assignments to modify:
  - `policy_assignments` - Map of policy assignment modifications:
    - `enforcement_mode` - (Optional) The enforcement mode for the policy assignment.
    - `identity` - (Optional) The type of managed identity for the policy assignment.
    - `identity_ids` - (Optional) List of user-assigned identity resource IDs.
    - `parameters` - (Optional) Map of parameter values for the policy assignment.
    - `non_compliance_messages` - (Optional) Set of non-compliance messages:
      - `message` - (Required) The non-compliance message.
      - `policy_definition_reference_id` - (Optional) The policy definition reference ID.
    - `resource_selectors` - (Optional) List of resource selectors:
      - `name` - (Required) The name of the resource selector.
      - `resource_selector_selectors` - (Optional) List of selector criteria:
        - `kind` - (Required) The kind of selector.
        - `in` - (Optional) Set of values to include.
        - `not_in` - (Optional) Set of values to exclude.
    - `overrides` - (Optional) List of policy overrides:
      - `kind` - (Required) The kind of override.
      - `value` - (Required) The override value.
      - `override_selectors` - (Optional) List of override selectors:
        - `kind` - (Required) The kind of selector.
        - `in` - (Optional) Set of values to include.
        - `not_in` - (Optional) Set of values to exclude.
- `management_group_hierarchy_settings` - (Optional) Settings for the management group hierarchy:
  - `default_management_group_name` - (Optional) The management group where new subscriptions are placed. Defaults to "sandbox" per CAF recommendation.
  - `require_authorization_for_group_creation` - (Optional) Require authorization for management group creation. Defaults to true.
  - `update_existing` - (Optional) Update existing management groups. Defaults to false.
- `partner_id` - (Optional) The partner ID for Azure partner attribution.
- `retries` - (Optional) Retry configurations for various resource types:
  - `management_groups`, `role_definitions`, `role_assignments`, `policy_definitions`, `policy_set_definitions`, `policy_assignments`, `policy_role_assignments`, `hierarchy_settings`, `subscription_placement` - Each has the following retry settings:
    - `error_message_regex` - (Optional) List of regex patterns to match error messages for retry.
    - `interval_seconds` - (Optional) The initial retry interval in seconds.
    - `max_interval_seconds` - (Optional) The maximum retry interval in seconds.
    - `multiplier` - (Optional) The multiplier for exponential backoff.
    - `randomization_factor` - (Optional) The randomization factor for retry intervals.
- `subscription_placement` - (Optional) Map of subscription placement configurations:
  - `subscription_id` - (Required) The subscription ID to place.
  - `management_group_name` - (Required) The target management group name.
- `timeouts` - (Optional) Timeout configurations for various resource types:
  - `management_group`, `role_definition`, `role_assignment`, `policy_definition`, `policy_set_definition`, `policy_assignment`, `policy_role_assignment` - Each has the following timeout settings:
    - `create` - (Optional) Timeout for create operations.
    - `delete` - (Optional) Timeout for delete operations.
    - `update` - (Optional) Timeout for update operations.
    - `read` - (Optional) Timeout for read operations.
- `dependencies` - (Optional) Dependency configurations:
  - `management_groups` - (Optional) Dependencies for management group creation.
  - `policy_role_assignments` - (Optional) Dependencies for policy role assignments.
  - `policy_assignments` - (Optional) Dependencies for policy assignments.
- `override_policy_definition_parameter_assign_permissions_set` - (Optional) Set of policy definition parameters to assign permissions:
  - `definition_name` - (Required) The policy definition name.
  - `parameter_name` - (Required) The parameter name.
- `override_policy_definition_parameter_assign_permissions_unset` - (Optional) Set of policy definition parameters to unset permissions:
  - `definition_name` - (Required) The policy definition name.
  - `parameter_name` - (Required) The parameter name.
- `management_group_role_assignments` - (Optional) Map of management group role assignments:
  - `management_group_name` - (Required) The target management group name.
  - `role_definition_id_or_name` - (Required) The role definition ID or name.
  - `principal_id` - (Required) The principal ID to assign the role to.
  - `description` - (Optional) Description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Skip service principal AAD check. Defaults to false.
  - `condition` - (Optional) The condition for the role assignment.
  - `condition_version` - (Optional) The condition version.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated managed identity resource ID.
  - `principal_type` - (Optional) The type of principal.
- `role_assignment_definition_lookup_enabled` - (Optional) Enable role definition lookup for assignments. Defaults to true.
- `policy_assignment_non_compliance_message_settings` - (Optional) Settings for policy non-compliance messages:
  - `fallback_message_enabled` - (Optional) Enable fallback messages.
  - `fallback_message` - (Optional) The fallback message text.
  - `fallback_message_unsupported_assignments` - (Optional) List of unsupported assignment names.
  - `enforcement_mode_placeholder` - (Optional) Placeholder for enforcement mode.
  - `enforced_replacement` - (Optional) Replacement text for enforced mode.
  - `not_enforced_replacement` - (Optional) Replacement text for not enforced mode.
- `role_assignment_name_use_random_uuid` - (Optional) Use random UUID for role assignment names. Defaults to true.
- `subscription_placement_destroy_behavior` - (Optional) Behavior when destroying subscription placement. Possible values: "parent", "intermediate_root", "custom", "default". Defaults to "default".
- `subscription_placement_destroy_custom_target_management_group_id` - (Optional) Target management group ID when using "custom" destroy behavior.

Details of the settings can be found in the module documentation at https://registry.terraform.io/modules/Azure/avm-ptn-alz
DESCRIPTION
}

variable "connectivity_subscription_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Subscription ID to place in the 'connectivity' management group.

Required when `management_groups_enabled = true`. Can be omitted when testing with management resources only.
DESCRIPTION

  validation {
    condition     = var.connectivity_subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.connectivity_subscription_id))
    error_message = "connectivity_subscription_id must be a valid GUID."
  }
}

variable "identity_subscription_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Subscription ID to place in the 'identity' management group.

Required when `management_groups_enabled = true` for standard ALZ deployments.
Can be omitted for cloud-native organisations using only Microsoft Entra ID (set `skip_identity_subscription_check = true`).
DESCRIPTION

  validation {
    condition     = var.identity_subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.identity_subscription_id))
    error_message = "identity_subscription_id must be a valid GUID."
  }
}

variable "management_subscription_id" {
  type        = string
  description = "Subscription ID for management resources (log analytics, DCRs, storage)."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.management_subscription_id))
    error_message = "management_subscription_id must be a valid GUID."
  }
}

variable "security_subscription_id" {
  type        = string
  default     = null
  description = "(Optional) Subscription ID to place in the 'security' management group. Only used when `management_groups_enabled = true`."

  validation {
    condition     = var.security_subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.security_subscription_id))
    error_message = "security_subscription_id must be a valid GUID."
  }
}

variable "skip_subscription_placement" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Skip platform subscription validation and placement.

When `true`:
- Skips connectivity_subscription_id and identity_subscription_id validation
- Only places management_subscription_id into the management group
- Allows testing the full ALZ deployment with a single subscription

Useful for development/testing when you only have a management subscription.
Not recommended for production deployments.
DESCRIPTION
}

variable "microsoft_defender_settings" {
  type = object({
    email_security_contact     = string
    export_resource_group_name = optional(string, "rg-asc-export")

    # Defender plans - set to true to enable (deploys via DeployIfNotExists policy)
    defender_plans = optional(object({
      ai                                = optional(bool, false)
      app_services                      = optional(bool, false)
      arm                               = optional(bool, false)
      containers                        = optional(bool, false)
      cosmos_dbs                        = optional(bool, false)
      cspm                              = optional(bool, false)
      key_vault                         = optional(bool, false)
      oss_db                            = optional(bool, false)
      servers                           = optional(bool, false)
      servers_vulnerability_assessments = optional(bool, false)
      sql                               = optional(bool, false)
      sql_on_vm                         = optional(bool, false)
      storage                           = optional(bool, false)
      tvm_check                         = optional(bool, false)
    }), {})

    # Sub-features for specific Defender plans
    subfeatures = optional(object({
      ai_prompt_evidence                                  = optional(bool, false)
      cspm_agentless_discovery_for_kubernetes             = optional(bool, false)
      cspm_agentless_vm_scanning                          = optional(bool, false)
      cspm_container_registries_vulnerability_assessments = optional(bool, false)
      cspm_entra_permissions_management                   = optional(bool, false)
      cspm_sensitive_data_discovery                       = optional(bool, false)
      servers_agentless_vm_scanning                       = optional(bool, false)
      storage_on_upload_malware_scanning                  = optional(bool, false)
      storage_sensitive_data_discovery                    = optional(bool, false)
    }), {})
  })
  default     = null
  description = <<DESCRIPTION
Microsoft Defender for Cloud configuration. Required when `management_groups_enabled = true`.
Can be omitted when deploying only management resources.

- `email_security_contact` - (Required) Email address for security alerts.
- `export_resource_group_name` - (Optional) Resource group name for ASC continuous export. Defaults to "rg-asc-export".
- `defender_plans` - (Optional) Toggle individual Defender plans. All default to false (Disabled).
  Set to true to enable via DeployIfNotExists policy.
- `subfeatures` - (Optional) Toggle sub-features for specific Defender plans. All default to false.
  These map to boolean parameters in the Deploy-MDFC-Config-H224 policy assignment.

Pricing overview (all plans default to disabled / no cost):

  Plan                              | Pricing Tier                | Billing Model
  --------------------------------- | --------------------------- | -----------------------------------
  ai                                | Defender for AI Services    | Per 1K tokens/month
  app_services                      | Service Layer               | Per App Service instance/hour
  arm                               | Service Layer               | Per subscription/month
  containers                        | Cloud Workload Protection   | Per vCore in K8s worker nodes
  cosmos_dbs                        | Databases                   | Per 100 RU/s/month
  cspm                              | Defender CSPM (paid)        | Per billable resource (VMs, Storage, DBs, Serverless)
  key_vault                         | Service Layer               | Per vault/month
  oss_db                            | Databases                   | Per instance/hour (PostgreSQL, MySQL, MariaDB)
  servers                           | Cloud Workload Protection   | Per server/hour (P1 or P2)
  servers_vulnerability_assessments | Cloud Workload Protection   | Included in Servers P2
  sql                               | Databases                   | Per SQL instance/hour
  sql_on_vm                         | Databases                   | Per SQL instance/hour
  storage                           | Cloud Workload Protection   | Per storage account/month + overage
  tvm_check                         | Cloud Workload Protection   | Sub-feature of Servers

Sub-features are included in their parent plan at no additional cost, except
`storage_on_upload_malware_scanning` which incurs an additional per-GB charge.

Full pricing details: https://azure.microsoft.com/en-us/pricing/details/defender-for-cloud/#pricing

Example - enable Defender for Servers with vulnerability assessments:

  microsoft_defender_settings = {
    email_security_contact = "security@example.com"
    defender_plans = {
      servers                           = true
      servers_vulnerability_assessments = true
    }
  }

Example - enable CSPM with agentless VM scanning:

  microsoft_defender_settings = {
    email_security_contact = "security@example.com"
    defender_plans = {
      cspm = true
    }
    subfeatures = {
      cspm_agentless_vm_scanning = true
    }
  }

Example - enable multiple plans:

  microsoft_defender_settings = {
    email_security_contact = "security@example.com"
    defender_plans = {
      servers      = true
      app_services = true
      sql          = true
      key_vault    = true
      storage      = true
    }
    subfeatures = {
      storage_on_upload_malware_scanning = true
    }
  }
DESCRIPTION

  validation {
    condition     = var.microsoft_defender_settings == null || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.microsoft_defender_settings.email_security_contact))
    error_message = "email_security_contact must be a valid email address."
  }
}
