# Management Groups, Policy and Role Assignments

Deploys management resources plus management group architecture with policies and role assignments.

## What Gets Deployed

**Management Resources:**

- Log Analytics Workspace (with diagnostic settings)
- Data Collection Rules (Change Tracking, VM Insights)
- User-Assigned Managed Identity (for Azure Monitor Agent)
- Resource Groups (with `CanNotDelete` locks)

**Management Groups:**

- ALZ management group architecture
- Policy definitions and assignments
- Subscription placement into management groups

## Use Case

- Full Azure Landing Zone deployment
- Centralised policy management across subscriptions

## Usage

```bash
cp management.tfvars ../../workspace_variables/prd_uksouth_terraform.tfvars
# Edit the tfvars file with your settings
eirctl infrastructure:plan
eirctl infrastructure:apply
```

## Required Pipeline Variables (`TF_VAR_`)

These values are injected as environment variables at pipeline runtime, not stored in tfvars files:

| Variable | Description |
| -------- | ----------- |
| `TF_VAR_company` | Company prefix for resource naming (e.g., "ensono") |
| `TF_VAR_region` | Azure region (e.g., "uksouth") |
| `TF_VAR_management_subscription_id` | Management subscription ID |
| `TF_VAR_connectivity_subscription_id` | Connectivity subscription ID (required unless `skip_subscription_placement = true`) |

## Required Variables (tfvars)

| Variable | Description |
| -------- | ----------- |
| `management_groups_enabled` | Set to `true` to deploy management group hierarchy |
| `microsoft_defender_settings.email_security_contact` | Email address for security alerts |

## Optional Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `identity_subscription_id` | `null` | Subscription ID for identity management group. Omit for cloud-native orgs using only Entra ID |
| `management_group_settings.parent_management_group_id` | Tenant root | Parent management group ID/name |
| `management_group_settings.default_management_group_name` | `"sandbox"` | Default MG for unassigned subscriptions |
| `security_subscription_id` | `null` | Auto-placed in security management group |
| `skip_subscription_placement` | `false` | Skip connectivity/identity validation for dev/testing |
| `resource_group_lock_enabled` | `true` | Enable CanNotDelete locks |
| `monitoring_alerts.enabled` | `false` | Enable health monitoring alerts |

## Auto-Computed Values

These policy default values are **automatically computed** from module outputs:

- `log_analytics_workspace_id`
- `ama_user_assigned_managed_identity_id`
- `ama_user_assigned_managed_identity_name`
- `ama_change_tracking_data_collection_rule_id` (when change tracking enabled)
- `ama_vm_insights_data_collection_rule_id` (when VM insights enabled)
- `ama_mdfc_sql_data_collection_rule_id` (when Defender for SQL enabled)

No need to manually construct resource IDs.

## Modifying Policies

Use `policy_assignments_to_modify` to change enforcement mode or parameters:

```hcl
management_group_settings = {
  policy_assignments_to_modify = {
    landingzones = {
      policy_assignments = {
        Enable-DDoS-VNET = { enforcement_mode = "DoNotEnforce" }
      }
    }
  }
}
```

## Permissions Required

- `Management Group Contributor` at Tenant Root Group or parent management group
- `Owner` on all subscriptions being placed into management groups
