# Management Resources Only

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
cp management.tfvars ../../terraform.tfvars
# Edit terraform.tfvars with your values
eirctl infrastructure:plan
eirctl infrastructure:apply
```

## Required Variables

| Variable | Description |
| -------- | ----------- |
| `company_name` | Company prefix for resource naming (e.g., "ensono") |
| `location` | Azure region (e.g., "uksouth") |
| `management_subscription_id` | Subscription ID to deploy resources |

## Optional Variables

All other variables have sensible defaults. See [variables documentation](../../README.md) for full list.

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `management_resource_settings.log_analytics_workspace_retention_in_days` | `30` | Log retention period |
| `management_resource_settings.log_analytics_workspace_sku` | `"PerGB2018"` | Pricing tier |
| `resource_group_lock_enabled` | `true` | Enable CanNotDelete locks |
| `monitoring_alerts.enabled` | `false` | Enable health monitoring alerts |

## Outputs

These outputs are consumed by the connectivity module via remote state:

- `log_analytics_workspace_id`
- `log_analytics_workspace_name`
- `log_analytics_workspace_guid`
