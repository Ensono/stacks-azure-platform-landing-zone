# Management Resources

Deploys management resources without management groups or policies.

## What Gets Deployed

- Log Analytics Workspace (with diagnostic settings)
- Data Collection Rules (Change Tracking, VM Insights)
- User-Assigned Managed Identity (for Azure Monitor Agent)
- Resource Groups (with `CanNotDelete` locks)

## Use Case

- Management groups are deployed separately or already exist
- Testing the module standalone before full ALZ deployment
- Connectivity module consumes outputs via remote state

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
| `TF_VAR_management_subscription_id` | Subscription ID to deploy resources |

## Optional Variables

All other variables have sensible defaults. See [variables documentation](../../README.md) for full list.

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `management_resource_settings.log_analytics_workspace_daily_quota_gb` | `10` | Daily ingestion cap in GB (`-1` for unlimited) |
| `management_resource_settings.log_analytics_workspace_retention_in_days` | `30` | Log retention period |
| `management_resource_settings.log_analytics_workspace_sku` | `"PerGB2018"` | Pricing tier |
| `resource_group_lock_enabled` | `true` | Enable CanNotDelete locks |
| `monitoring_alerts.enabled` | `false` | Enable health monitoring alerts |

## Outputs

These outputs are consumed by the connectivity module via remote state:

- `log_analytics_workspace_id`
- `log_analytics_workspace_guid`
