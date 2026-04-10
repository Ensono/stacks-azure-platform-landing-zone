# Stacks Azure Platform Landing Zone - Management

## Overview

The **Stacks Azure Platform Landing Zone Management** module deploys
management resources using the below Azure Verified Modules:

[Management Groups, Policy and Role
Assignments](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest)

[Management
Resources](https://registry.terraform.io/modules/Azure/avm-ptn-alz-management/azurerm/latest)

It provides centralised logging, monitoring, and an optional default
management group architecture for Azure Landing Zones.

This module is designed for **platform engineers** who need to provision
a centralised management foundation for logging, monitoring, governance,
and policy enforcement across Azure subscriptions.

### Log Analytics Workspace Strategy

This module deploys a **single Log Analytics Workspace** in the
management subscription for platform operational data. This follows
[Microsoft’s primary
recommendation](https://learn.microsoft.com/azure/azure-monitor/logs/workspace-design)
to start with a single workspace and only add more when specific
requirements demand it.

#### Why a Single Workspace

- **Simplified operations** — One workspace to manage, query, and
  monitor

- **Cost efficiency** — Consolidating data may qualify for commitment
  tier discounts (15-25% savings at 100+ GB/day)

- **Better visibility** — All platform operational data in one place
  makes cross-resource correlation straightforward

- **Resource-context RBAC** — Users with read access to an Azure
  resource automatically inherit permissions to that resource’s logs,
  without needing workspace-level access

#### When to Consider a Second Workspace

Microsoft recommends adding workspaces only when driven by specific
requirements:

- **Security data (Microsoft Sentinel)** — When Sentinel is enabled, all
  data in the workspace is subject to Sentinel pricing. A dedicated
  security workspace avoids applying Sentinel costs to operational data.
  Alternatively, use a combined workspace with table-level RBAC if the
  commitment tier discount outweighs the pricing impact

- **Data sovereignty** — Regulatory requirements to keep data in
  specific Azure regions

- **Data ownership** — Organisational boundaries (subsidiaries,
  affiliates) requiring strict data segregation

- **Split billing** — When cost reporting via Azure Cost Management is
  insufficient for chargeback requirements

See the [Best Practices](#best-practices) section for detailed workspace
design guidance with Microsoft documentation references.

### What This Module Deploys

The module comprises two conditionally-enabled module chains:

1.  **Management Resources** — Log Analytics Workspace (platform logs),
    Data Collection Rules, User Assigned Managed Identity, and health
    monitoring alerts

2.  **Management Group Hierarchy** (optional) — ALZ management group
    hierarchy with policy-driven governance

### Architecture Overview

``` mermaid
flowchart TB
    subgraph Management["Management Subscription"]
        direction TB

        subgraph Resources["Management Resource Group"]
            LAW["Log Analytics Workspace"]
            DCR["Data Collection Rules"]
            UAI["User Assigned Identity (AMA)"]
        end

        subgraph Optional["Management Groups (Optional)"]
            MG["Management Group Hierarchy"]
            Policy["Azure Policies"]
        end
    end

    LAW --> DCR
    DCR --> UAI
```

### Module Chain

    management_resources → management_groups

### Prerequisites

- An Azure subscription designated as the **management subscription**

- Terraform ~> 1.12, AzureRM ~> 4.0, AzAPI ~> 2.0

- For management groups: `Management Group Contributor` and
  `User Access Administrator` at the target management group scope, and
  `Owner` at the target subscription scope. These permissions are
  required to create resources, assign policies, and configure
  role-based access control (RBAC) during deployment.

## Features

The following table summarises the features available in this module and
their default state.

| Feature                      | Default     | Description                                                                                                                                                                                                                      |
|------------------------------|-------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Log Analytics Workspace      | ✅ Enabled  | Central platform logging hub for operational telemetry (activity logs, diagnostics, metrics). Private-only by default with Entra ID authentication. Security logs are sent to a separate workspace in the security subscription. |
| Data Collection Rules        | ✅ Enabled  | Change Tracking and VM Insights enabled by default. Defender for SQL is optional.                                                                                                                                                |
| Azure Monitor Agent Identity | ✅ Enabled  | User-assigned managed identity for policy-driven AMA deployment.                                                                                                                                                                 |
| Resource Group Locks         | ✅ Enabled  | `CanNotDelete` locks on resource groups to prevent accidental deletion.                                                                                                                                                          |
| Log Analytics Diagnostics    | ✅ Enabled  | Self-monitoring diagnostic settings (Audit, SummaryLogs, AllMetrics).                                                                                                                                                            |
| Subscription Activity Logs   | ✅ Enabled  | Routes Activity Logs (Administrative, Security, Policy, ServiceHealth, ResourceHealth, Alert, Recommendation) into Log Analytics.                                                                                                |
| Health Monitoring Alerts     | ❌ Disabled | Ingestion latency, search availability, query failures/runtime, and data ingestion guardrails. Requires an Action Group.                                                                                                         |
| Management Groups            | ❌ Disabled | ALZ management group hierarchy with Azure Policy assignments and Microsoft Defender for Cloud enablement.                                                                                                                        |

## Quick Start

Deploy the management module with minimal configuration to get
centralised logging up and running.

### Minimal Deployment

Deploys a Log Analytics Workspace and Data Collection Rules with
sensible defaults:

``` hcl
company                    = "ensono"
region                     = "uksouth"
management_subscription_id = "00000000-0000-0000-0000-000000000000"
```

This provisions:

- A **Log Analytics Workspace** with private-only access and Entra ID
  authentication

- **Data Collection Rules** for Change Tracking and VM Insights

- A **User Assigned Managed Identity** for Azure Monitor Agent

- **Self-monitoring diagnostics** on the workspace

- **Subscription Activity Log** routing to the workspace

### Deployment Order

When deploying the full platform, the management module is always
deployed **first**:

    1. Management Module      ← you are here
    2. Connectivity Module    (consumes LAW ID and GUID)
    3. Identity Module        (consumes LAW ID)
    4. Security Module        (has its own Log Analytics Workspace)

### What’s Next?

- [Architecture](#architecture) — Management group hierarchy and
  architecture details

- [Examples](#examples) — Configuration examples for common scenarios

- [Integration](#integration) — How this module connects to other
  landing zone modules

## Architecture

### Management Group Hierarchy

When `management_groups_enabled = true`, the module deploys the standard
Azure Landing Zone management group architecture:

``` mermaid
flowchart TB
    Tenant["Tenant Root Group"]
    ALZ["Azure Landing Zones<br/><i>root policies</i>"]

    Platform["Platform"]
    LandingZones["Landing Zones"]
    Sandbox["Sandbox"]
    Decommissioned["Decommissioned"]

    Management["Management<br/><i>management subscription</i>"]
    Connectivity["Connectivity<br/><i>connectivity subscription</i>"]
    Identity["Identity<br/><i>identity subscription</i>"]
    Security["Security<br/><i>security subscription</i>"]

    Corp["Corp<br/><i>private workloads</i>"]
    Online["Online<br/><i>public workloads</i>"]

    Tenant --> ALZ
    ALZ --> Platform
    ALZ --> LandingZones
    ALZ --> Sandbox
    ALZ --> Decommissioned

    Platform --> Management
    Platform --> Connectivity
    Platform --> Identity
    Platform --> Security

    LandingZones --> Corp
    LandingZones --> Online

    style ALZ fill:#0078d4,color:#fff
    style Platform fill:#5c2d91,color:#fff
    style LandingZones fill:#008272,color:#fff
    style Management fill:#5c2d91,color:#fff
    style Connectivity fill:#5c2d91,color:#fff
    style Identity fill:#5c2d91,color:#fff
    style Security fill:#5c2d91,color:#fff
    style Corp fill:#008272,color:#fff
    style Online fill:#008272,color:#fff
```

<div class="note">

Platform subscriptions are automatically placed into their respective
management groups when subscription IDs are provided.

</div>

<div class="note">

Management Group deployments require the deployment identity to have
`Management Group Contributor` and `User Access Administrator` at the
target management group scope, and `Owner` at the target subscription
scope. These permissions are required to create resources, assign
policies, and configure RBAC during deployment.

</div>

### Policy Assignments

Archetype-based **Azure Policy assignments** from the [ALZ
Library](https://github.com/Azure/Azure-Landing-Zones-Library/tree/main/platform/alz)
are applied per management group. Policy default values and assignments
are managed in the `locals_policy_assignments.tf` file.

In addition to the standard ALZ Library policies, the module includes
custom audit policy assignments in the `lib/policy_assignments/`
directory. These are added to the root management group via the
`root_custom` archetype override in
`lib/archetype_definitions/root_custom.alz_archetype_override.yaml`:

- **Audit-CIS-Azure** — CIS Microsoft Azure Foundations Benchmark v2.0.0

- **Audit-GDPR** — EU General Data Protection Regulation (GDPR) 2016/679

- **Audit-ISO27001** — ISO 27001:2013

To add or remove custom policy assignments, modify the
`policy_assignments_to_add` list in the relevant archetype override
file.

### Microsoft Defender for Cloud

When management groups are enabled, `DeployIfNotExists` policies for
Microsoft Defender for Cloud are deployed. All Defender plans default to
**disabled** - enable individual plans via
`microsoft_defender_settings.defender_plans` (e.g., `servers`,
`key_vault`, `storage`).

The `microsoft_defender_settings.email_security_contact` is required
when management groups are enabled, ensuring security alerts always have
a notification target.

See the [API Reference](#api-reference) for the full list of available
Defender plans, sub-features, and pricing details.

### Azure Monitor Private Link Scope (AMPLS)

This module is designed to work with AMPLS deployed by the connectivity
module. By default, Log Analytics is configured with secure settings
that require private connectivity:

<div class="note">

This module deploys a single Log Analytics Workspace for platform
operational data, following [Microsoft’s
recommendation](https://learn.microsoft.com/azure/azure-monitor/logs/workspace-design)
to start with a single workspace. If your organisation requires a
dedicated security workspace for Microsoft Sentinel or Defender for
Cloud, deploy it separately - see [Workspace Design](#workspace-design)
in Best Practices for guidance.

</div>

| Setting                        | Default | Description                                |
|--------------------------------|---------|--------------------------------------------|
| `internet_ingestion_enabled`   | `false` | Blocks data ingestion from public internet |
| `internet_query_enabled`       | `false` | Blocks queries from public internet        |
| `local_authentication_enabled` | `false` | Requires Entra ID authentication           |

The deployment order ensures private connectivity is established:

1.  **Management module** — Creates Log Analytics Workspace with
    private-only settings

2.  **Connectivity module** — Creates AMPLS and links Log Analytics to
    private network

<div class="warning">

Enabling public access reduces security. Use only in development
environments where AMPLS is not deployed. See [Examples](#examples) for
development configuration.

</div>

## Examples

### Customising Management Resources

Override specific settings while using defaults for the rest:

``` hcl
company                    = "ensono"
region                     = "uksouth"
management_subscription_id = "00000000-0000-0000-0000-000000000000"

# Customise retention and disable VM Insights DCR
management_resource_settings = {
  log_analytics_workspace_retention_in_days = 180

  data_collection_rules = {
    vm_insights = { enabled = false }
  }
}
```

### Full Azure Landing Zone with Management Groups

Deploy a complete Azure Landing Zone management group architecture with
policies:

``` hcl
company                    = "ensono"
region                     = "uksouth"
management_subscription_id = "00000000-0000-0000-0000-000000000000"

# Platform subscriptions
connectivity_subscription_id = "11111111-1111-1111-1111-111111111111"  # Required unless skip_subscription_placement = true

# Optional: Identity can be omitted for cloud-native orgs using only Microsoft Entra ID
# identity_subscription_id = "22222222-2222-2222-2222-222222222222"

# Optional: Dedicated security subscription for centralised security tooling
# security_subscription_id = "33333333-3333-3333-3333-333333333333"

# Enable management groups (deploys under tenant root group by default)
management_groups_enabled = true

# Required when management groups are enabled
microsoft_defender_settings = {
  email_security_contact = "security@example.invalid"
}
```

<div class="note">

`microsoft_defender_settings` is required when
`management_groups_enabled = true`. All Defender plans default to
disabled - enable individual plans via `defender_plans`. See the [API
Reference](#api-reference) for full configuration options.

</div>

### Development / Testing (Single Subscription)

For testing with only a management subscription:

``` hcl
company                    = "ensono"
region                     = "uksouth"
management_subscription_id = "00000000-0000-0000-0000-000000000000"

management_groups_enabled    = true
skip_subscription_placement  = true  # Skips connectivity subscription validation

microsoft_defender_settings = {
  email_security_contact = "security@example.invalid"
}
```

### Enabling Public Access (Development Only)

For development environments without private networking:

``` hcl
management_resource_settings = {
  # Enable public access for development/testing (not recommended for production)
  log_analytics_workspace_internet_ingestion_enabled   = true
  log_analytics_workspace_internet_query_enabled       = true
  log_analytics_workspace_local_authentication_enabled = true
}
```

<div class="warning">

Enabling public access reduces security. Use only in development
environments where AMPLS is not deployed.

</div>

### Health Monitoring Alerts

Enable health monitoring alerts with custom thresholds:

``` hcl
monitoring_alerts = {
  action_group_id                         = "/subscriptions/.../actionGroups/platform-alerts"
  ingestion_latency_threshold_seconds     = 60    # default 120
  data_ingest_threshold_gb                = 50    # default 100
  search_availability_threshold_percent   = 99.5  # default 99
  query_duration_threshold_ms             = 20000 # default 15000
  enable_query_failure_alerts             = true  # default true
  query_failure_threshold                 = 10    # default 5
}
```

<div class="note">

An Action Group must be provided when alerts are enabled. Create an
Action Group in Azure Monitor first to receive notifications via email,
SMS, webhook, or other channels.

</div>

### Commitment Tier Pricing

For predictable workloads with 100+ GB/day ingestion:

``` hcl
management_resource_settings = {
  log_analytics_workspace_sku                                = "CapacityReservation"
  log_analytics_workspace_reservation_capacity_in_gb_per_day = 100  # 100, 200, 300, 400, or 500 GB/day
}
```

### Custom Data Collection Rule Names

Override the default DCR names:

``` hcl
management_resource_settings = {
  data_collection_rules = {
    change_tracking = { name = "dcr-custom-change-tracking" }
    vm_insights     = { name = "dcr-custom-vm-insights" }
    defender_sql    = { enabled = true, name = "dcr-custom-defender-sql" }
  }
}
```

See [Resource Naming](#naming) for the default DCR naming conventions.

## Resource Naming

Resources follow [Cloud Adoption Framework
(CAF)](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
naming conventions using the [Azure Naming
module](https://registry.terraform.io/modules/Azure/naming/azurerm/latest).

### Naming Conventions

The naming suffix is composed of:
`{company_3char}-{geo_code}-{workspace}-{component}-001`

Where `{workspace}` is the Terraform workspace name (e.g., `default`,
`dev`, `prod`).

| Resource               | Pattern                                        | Example                       |
|------------------------|------------------------------------------------|-------------------------------|
| Resource Group         | `rg-{company}-{geo_code}-{workspace}-man-001`  | `rg-ens-uks-default-man-001`  |
| Log Analytics          | `log-{company}-{geo_code}-{workspace}-man-001` | `log-ens-uks-default-man-001` |
| User Assigned Identity | `uai-ama`                                      | `uai-ama`                     |
| Data Collection Rule   | `dcr-{type}`                                   | `dcr-change-tracking`         |

### Naming Strategy

The module uses deterministic naming with `001` suffixes for all
resources by default. This ensures resource names are known at plan
time, which is [required for ALZ policy
assignments](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest#unknown-values—​depends-on).

### Data Collection Rule Names

DCR names use AVM defaults but can be customised:

| DCR              | Default Name          | Description                         |
|------------------|-----------------------|-------------------------------------|
| Change Tracking  | `dcr-change-tracking` | File and registry change monitoring |
| VM Insights      | `dcr-vm-insights`     | VM performance and dependency data  |
| Defender for SQL | `dcr-defender-sql`    | SQL security telemetry              |

See [Examples](#examples) for overriding DCR names.

## Integration

This module is the foundation of the Azure Platform Landing Zone. Its
outputs are consumed by all downstream landing zone modules via
Terraform remote state.

### Outputs for Downstream Modules

| Output                         | Consumed By                                                  |
|--------------------------------|--------------------------------------------------------------|
| `log_analytics_workspace_id`   | Connectivity (AMPLS, diagnostics), Identity (VM diagnostics) |
| `log_analytics_workspace_guid` | Connectivity (Traffic Analytics)                             |

### Module Dependency Chain

    Management (this module)
      ├── Connectivity Hub-Spoke  (consumes LAW ID + GUID)
      ├── Connectivity Virtual WAN (consumes LAW ID + GUID)
      └── Identity                (consumes LAW ID)

### Connectivity Module Integration

The connectivity module uses these outputs for:

- **AMPLS** — Links the Log Analytics Workspace to a private network

- **Diagnostic settings** — Sends firewall, bastion, and gateway logs to
  the workspace

- **Traffic Analytics** — Uses the workspace GUID for network flow
  analytics

### Identity Module Integration

The identity module reads management outputs for:

- **VM diagnostics** — Sends domain controller logs and metrics to the
  workspace via `log_analytics_workspace_id`

### Security Module Integration

If your organisation deploys a dedicated security workspace (for
Microsoft Sentinel or Defender for Cloud), that module manages its own
Log Analytics Workspace and does not consume management module outputs.
See [Workspace Design](#workspace-design) in Best Practices for guidance
on when a separate security workspace is warranted.

### Downstream Module Configuration

Downstream modules consume management outputs via Terraform remote
state. Configure the following in the connectivity or identity module’s
`terraform.tfvars`:

``` hcl
management_remote_state = {
  storage_account_name = "<tfstate-storage-account>"
}
```

<div class="note">

The `management_remote_state` variable is defined in the downstream
modules, not in the management module. See the connectivity module
documentation for full configuration options.

</div>

## Health Monitoring Alerts

The module supports optional Azure Monitor health monitoring alerts to
ensure the observability infrastructure remains healthy.

Alerts require an **Action Group** so notifications always reach
operations teams. Provide an action group ID (and optional threshold
overrides) to enable all alerts.

The `enabled` flag uses a three-state logic:

- **Not set (default)** — Alerts are auto-enabled when `action_group_id`
  is provided.

- **`true`** — Alerts are explicitly enabled; `action_group_id` must
  also be provided.

- **`false`** — Alerts are explicitly disabled, even if
  `action_group_id` is set.

### Alert Types

| Alert                    | Severity          | Description                                                            |
|--------------------------|-------------------|------------------------------------------------------------------------|
| Ingestion Latency        | 2 (Warning)       | Triggers when data ingestion latency exceeds threshold                 |
| Search Availability      | 2 (Warning)       | Triggers when `SearchableResultsAvailability` drops below threshold    |
| Query Failures           | 2 (Warning)       | Triggers when query failures exceed threshold                          |
| Slow Query Runtime       | 3 (Informational) | Triggers when `QueryStoreRuntimeStatistics` shows long-running queries |
| Data Ingestion Guardrail | 3 (Informational) | Triggers when daily data ingestion exceeds budgeted GB                 |

### Configuration

``` hcl
monitoring_alerts = {
  action_group_id                         = "/subscriptions/.../actionGroups/platform-alerts"
  ingestion_latency_threshold_seconds     = 60    # default 120
  data_ingest_threshold_gb                = 50    # default 100
  search_availability_threshold_percent   = 99.5  # default 99
  query_duration_threshold_ms             = 20000 # default 15000
  enable_query_failure_alerts             = true  # default true
  query_failure_threshold                 = 10    # default 5
}
```

<div class="note">

Create an Action Group in Azure Monitor before enabling alerts to
receive notifications via email, SMS, webhook, or other channels.

</div>

See [Examples](#examples) for a full configuration example and [Best
Practices](#best-practices) for cost considerations.

## Best Practices

### Workspace Design

This module follows Microsoft’s recommendation to start with a single
Log Analytics Workspace and only introduce additional workspaces when
driven by specific requirements.

#### Microsoft Guidance Summary

| Criterion              | Single Workspace                                  | Multiple Workspaces                                                                             |
|------------------------|---------------------------------------------------|-------------------------------------------------------------------------------------------------|
| Default recommendation | ✅ Start here                                     | Only when required                                                                              |
| Operational complexity | Lower — one workspace to manage and query         | Higher — cross-workspace queries, duplicate config                                              |
| Cost                   | May qualify for commitment tier discounts         | Each workspace billed independently                                                             |
| Data visibility        | Full cross-resource correlation                   | Requires cross-workspace queries (max 100 workspaces)                                           |
| Access control         | Resource-context RBAC + table-level RBAC          | Workspace-level separation                                                                      |
| Data retention         | Per-table retention settings within one workspace | Per-workspace defaults (useful when same table needs different retention for different sources) |

#### Security Data (Microsoft Sentinel)

The most common reason to add a second workspace is Microsoft Sentinel:

- When Sentinel is enabled, **all data in the workspace** is subject to
  [Sentinel
  pricing](https://learn.microsoft.com/azure/azure-monitor/logs/cost-logs#workspaces-with-microsoft-sentinel)
  — even operational data

- A workspace with Sentinel gets **90 days free retention** (vs 31 days
  without Sentinel)

- Separating security data allows independent RBAC, retention, and cost
  management for security teams

| Approach                | When to Use                                                                                                                                                       |
|-------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Combined workspace**  | Low data volumes where commitment tier discount offsets Sentinel pricing on operational data. Use table-level RBAC to restrict security table access.             |
| **Separate workspaces** | Higher data volumes, strict security/ops team separation, or when Sentinel pricing on operational data is a concern. Use cross-workspace queries for correlation. |

<div class="tip">

If you later need a dedicated security workspace, deploy it using the
[`avm-res-operationalinsights-workspace`](https://registry.terraform.io/modules/Azure/avm-res-operationalinsights-workspace/azurerm/latest)
resource module for a lightweight workspace without the management
overhead of the pattern module.

</div>

### Reliability and Zone Redundancy

The module implements Azure Well-Architected Framework reliability best
practices.

#### Log Analytics Workspace

| Feature            | Status       | Notes                                                                 |
|--------------------|--------------|-----------------------------------------------------------------------|
| Data Resilience    | ✅ Automatic | Data replicated across availability zones in supported regions        |
| Service Resilience | ⚠️ Regional  | Requires dedicated cluster for full zone-redundant service operations |
| Diagnostics        | ✅ Enabled   | Self-monitoring via diagnostic settings                               |

**Supported regions for data resilience**: UK South, West Europe, East
US, West US 2, and
[others](https://learn.microsoft.com/azure/azure-monitor/logs/availability-zones#supported-regions).

#### High Availability Requirements

For mission-critical deployments requiring service resilience (not just
data resilience):

``` hcl
# Consider dedicated clusters for high-volume, mission-critical workloads
# Requires 500+ GB/day commitment
management_resource_settings = {
  log_analytics_workspace_sku = "CapacityReservation"
  log_analytics_workspace_reservation_capacity_in_gb_per_day = 500
}
```

<div class="note">

Dedicated clusters provide service resilience (query availability during
zone failures) but require minimum 500 GB/day commitment. For most
workloads, standard data resilience is sufficient.

</div>

### Cost Optimisation

The module follows Azure Well-Architected Framework cost optimisation
guidance.

#### Log Analytics Workspace Cost Settings

| Setting                                                      | Default     | Cost Impact                                                                  |
|--------------------------------------------------------------|-------------|------------------------------------------------------------------------------|
| `log_analytics_workspace_daily_quota_gb`                     | `10` GB/day | Safety cap to prevent runaway costs. Increase for higher-volume environments |
| `log_analytics_workspace_sku`                                | `PerGB2018` | Pay-as-you-go pricing                                                        |
| `log_analytics_workspace_reservation_capacity_in_gb_per_day` | `null`      | Use commitment tiers for 15-25% savings                                      |

#### Estimated Monthly Costs

The following table provides estimated monthly costs for typical
deployments. Actual costs vary based on data ingestion volume,
retention, and region.

| Resource                       | Configuration        | Estimated Cost (GBP) |
|--------------------------------|----------------------|----------------------|
| Log Analytics Workspace        | PerGB2018, ~5 GB/day | ~£58/month           |
| Data Collection Rules          | N/A                  | Included             |
| User Assigned Managed Identity | N/A                  | Free                 |
| Management Groups              | N/A                  | Free                 |
| Azure Policies                 | N/A                  | Free                 |

**Typical Total**: ~£58/month (varies by ingestion volume, capped at 10
GB/day by default)

<div class="tip">

Use the [Azure Pricing
Calculator](https://azure.microsoft.com/pricing/calculator/) for precise
estimates. Consider commitment tiers for 15-25% savings on predictable
workloads (100+ GB/day). The default
`log_analytics_workspace_daily_quota_gb` of 10 GB/day provides cost
protection — this can be increased or set to `-1` for unlimited in
higher-volume environments.

</div>

### Security

#### Private-Only Access

By default, the Log Analytics Workspace is configured for private-only
access:

- Internet ingestion disabled

- Internet queries disabled

- Local authentication disabled (Entra ID only)

This requires AMPLS to be deployed by the connectivity module for
network connectivity. See [Architecture](#architecture) for the
deployment order and [Enabling Public Access](#examples) for development
configuration.

#### Resource Locks

Resource groups are protected with `CanNotDelete` locks by default
(`resource_group_lock_enabled = true`). This prevents accidental
deletion of the management resource group and its contents.

## Advanced Configuration

This section covers management group customisation for organisations
that need to modify the default ALZ hierarchy. For the default
architecture overview, see [Architecture](#architecture).

### Customising Management Groups

#### Updating the Management Group Architecture

If the architecture needs to be changed, update the
`alz_custom.alz_architecture_definition.yaml` file:

    deploy/terraform/lib/architecture_definitions/alz_custom.alz_architecture_definition.yaml

#### Using an Existing Management Group

It is recommended to keep the hierarchy flat where possible, but if an
existing management group is being used as the root, update the
architecture definition file. For example:

``` yaml
management_groups:
  - id: existing_group
    display_name: Existing Group
    archetypes:
      - root
    parent_id: null # setting to null indicates to the provider that we should use the parent resource id
    exists: true
```

#### Using ALZ Library Policies Without Customisation

The module by default uses the standard [ALZ
Library](https://github.com/Azure/Azure-Landing-Zones-Library/tree/main/platform/alz)
policies without custom overrides. Policy default values and assignments
are managed in the `locals_policy_assignments.tf` file.

#### Custom Policy Overrides

To customise policy assignments for specific management groups, create
or modify archetype override files in:

    deploy/terraform/lib/archetype_definitions/

Override files use the naming convention
`*_custom.alz_archetype_override.yaml`.

See the [ALZ
Library](https://github.com/Azure/Azure-Landing-Zones-Library/tree/main/platform/alz)
for the full list of available archetypes and policies.

### Unit Tests

The module includes Terraform unit tests in `deploy/terraform/tests/`
that validate configuration logic using mock providers. These tests run
in CI when changes are made to the module and do not require Azure
credentials.

#### Running Tests

``` bash
eirctl tests
```

To run a specific test file:

``` bash
eirctl tests TF_TEST_FILTER=tests/naming.tftest.hcl
```

#### Test Coverage

| Test File                           | Test Cases                                                                                                                                                                                                                                                              | What It Validates                                                                       |
|-------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `naming.tftest.hcl`                 | naming_module_produces_caf_prefixes                                                                                                                                                                                                                                     | Resource naming follows CAF conventions                                                 |
| `locals_safe_defaults.tftest.hcl`   | policy_defaults_computed_safely                                                                                                                                                                                                                                         | Policy default values are computed without errors when settings are null                |
| `monitoring_alerts.tftest.hcl`      | monitoring_alerts_auto_enabled_with_action_group, monitoring_alerts_disabled_without_action_group, ingest_threshold_gb_to_bytes_conversion, monitoring_alerts_explicit_disable_overrides_action_group                                                                   | Alert auto-enablement, threshold conversions, and explicit disable behaviour            |
| `policy_assignments.tftest.hcl`     | defender_plans_all_disabled_by_default, defender_plans_selective_enable, defender_settings_propagated, policy_values_empty_when_resources_disabled, policy_values_populated_when_resources_enabled, policy_values_dcr_selective_disable, private_dns_zones_not_enforced | Defender plan defaults, policy value propagation, DCR toggles, and DNS zone enforcement |
| `subscription_placement.tftest.hcl` | all_subscriptions_placed, skip_placement_only_management, security_subscription_omitted_by_default, subscription_placement_custom_override                                                                                                                              | Subscription placement into management groups, skip logic, and custom overrides         |

#### Writing New Tests

Tests use `.tftest.hcl` files with mock providers. Follow the
established patterns:

- Use `command = plan` with `state_key` to isolate test runs

- Assert against locals and computed values, not Azure API responses

- Enable `parallel = true` at the test level

- Cover default values, feature flag propagation, and edge cases

See the existing test files and `tests/terraform.tfvars` for reference.

## Troubleshooting

### Common Issues

#### AMPLS / Private Connectivity

**Symptom**: Log Analytics Workspace rejects ingestion or queries after
deployment.

**Cause**: The workspace is configured with
`internet_ingestion_enabled = false` and
`internet_query_enabled = false` by default (see
[Architecture](#architecture) for details). Without AMPLS (deployed by
the connectivity module), there is no network path.

**Resolution**: Either deploy the connectivity module to create AMPLS,
or enable public access for development:

``` hcl
management_resource_settings = {
  log_analytics_workspace_internet_ingestion_enabled   = true
  log_analytics_workspace_internet_query_enabled       = true
  log_analytics_workspace_local_authentication_enabled = true
}
```

#### Management Group Permissions

**Symptom**: `AuthorizationFailed` errors when deploying management
groups.

**Cause**: The deploying identity requires
`Management Group Contributor` and `User Access Administrator` at the
target management group scope, and `Owner` at the target subscription
scope. These permissions are required to create resources, assign
policies, and configure RBAC during deployment.

**Resolution**: Ensure the service principal or user has the required
permissions at the correct scopes.

#### Subscription Placement Validation

**Symptom**: Terraform validation fails when management groups are
enabled but the connectivity subscription ID is not provided.

**Cause**: The module validates that `connectivity_subscription_id` is
provided when management groups are enabled.

**Resolution**: Either provide `connectivity_subscription_id` or set
`skip_subscription_placement = true` for development/testing with a
single subscription. See the [Development / Testing](#examples) example.

#### ALZ Policy Assignment Failures

**Symptom**: Policy assignment fails with "unknown values" or
"depends_on" errors.

**Cause**: Resource names must be deterministic and known at plan time
for ALZ policy assignments.

**Resolution**: Ensure the naming module produces deterministic names.
Avoid using `random` or computed values in resource names that are
referenced by policy assignments. See [Resource Naming](#naming) for
naming conventions.

## API Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                         | Version  |
|------------------------------------------------------------------------------|----------|
| <span id="requirement_terraform"></span> [terraform](#requirement_terraform) | ~> 1.12 |
| <span id="requirement_alz"></span> [alz](#requirement_alz)                   | 0.20.2   |
| <span id="requirement_azapi"></span> [azapi](#requirement_azapi)             | ~> 2.0  |
| <span id="requirement_azurerm"></span> [azurerm](#requirement_azurerm)       | ~> 4.0  |

## Providers

| Name                                                                   | Version |
|------------------------------------------------------------------------|---------|
| <span id="provider_azapi"></span> [azapi](#provider_azapi)             | ~> 2.0 |
| <span id="provider_azurerm"></span> [azurerm](#provider_azurerm)       | ~> 4.0 |
| <span id="provider_terraform"></span> [terraform](#provider_terraform) | n/a     |

## Modules

| Name                                                                                                | Source                                        | Version |
|-----------------------------------------------------------------------------------------------------|-----------------------------------------------|---------|
| <span id="module_azure_regions"></span> [azure_regions](#module_azure_regions)                      | Azure/avm-utl-regions/azurerm                 | 0.9.3   |
| <span id="module_management_groups"></span> [management_groups](#module_management_groups)          | Azure/avm-ptn-alz/azurerm                     | 0.18.0  |
| <span id="module_management_resources"></span> [management_resources](#module_management_resources) | Azure/avm-ptn-alz-management/azurerm          | 0.9.0   |
| <span id="module_naming"></span> [naming](#module_naming)                                           | Azure/naming/azurerm                          | 0.4.3   |
| <span id="module_resource_groups"></span> [resource_groups](#module_resource_groups)                | Azure/avm-res-resources-resourcegroup/azurerm | 0.2.1   |

## Resources

| Name                                                                                                                                                                                        | Type        |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [azurerm_monitor_metric_alert.law_data_ingest](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                        | resource    |
| [azurerm_monitor_metric_alert.law_ingestion_latency](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                  | resource    |
| [azurerm_monitor_metric_alert.law_search_availability](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.law_query_failures](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.law_query_runtime](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)  | resource    |
| [terraform_data.monitoring_alerts_require_action_group](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                             | resource    |
| [terraform_data.validate_defender_settings](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                                         | resource    |
| [terraform_data.validate_subscriptions](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                                             | resource    |
| [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config)                                                                   | data source |

## Inputs

<table>
<colgroup>
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Name</th>
<th style="text-align: left;">Description</th>
<th style="text-align: left;">Type</th>
<th style="text-align: left;">Default</th>
<th style="text-align: left;">Required</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><p><span id="input_company"></span> <a
href="#input_company">company</a></p></td>
<td style="text-align: left;"><p>Company name used in resource naming.
The first 3 characters are used as a prefix (e.g., 'ensono' becomes
'ens').</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p>n/a</p></td>
<td style="text-align: left;"><p>yes</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_management_subscription_id"></span> <a
href="#input_management_subscription_id">management_subscription_id</a></p></td>
<td style="text-align: left;"><p>Subscription ID for management
resources (log analytics, DCRs, storage).</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p>n/a</p></td>
<td style="text-align: left;"><p>yes</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span id="input_region"></span> <a
href="#input_region">region</a></p></td>
<td style="text-align: left;"><p>Primary Azure region for management
resources (e.g., 'uksouth').</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p>n/a</p></td>
<td style="text-align: left;"><p>yes</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_connectivity_subscription_id"></span> <a
href="#input_connectivity_subscription_id">connectivity_subscription_id</a></p></td>
<td style="text-align: left;"><p>Subscription ID to place in the
'connectivity' management group.</p>
<p>Required when <code>management_groups_enabled = true</code>. Can be
omitted when testing with management resources only.</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p><code>null</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_enable_avm_telemetry"></span> <a
href="#input_enable_avm_telemetry">enable_avm_telemetry</a></p></td>
<td style="text-align: left;"><p>Enable telemetry collection for Azure
Verified Modules. See <a
href="https://aka.ms/avm/telemetryinfo">https://aka.ms/avm/telemetryinfo</a>.</p></td>
<td style="text-align: left;"><p><code>bool</code></p></td>
<td style="text-align: left;"><p><code>false</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_identity_subscription_id"></span> <a
href="#input_identity_subscription_id">identity_subscription_id</a></p></td>
<td style="text-align: left;"><p>(Optional) Subscription ID to place in
the 'identity' management group.</p>
<p>When provided, the subscription is placed in the 'identity'
management group. Can be omitted for cloud-native organisations using
only Microsoft Entra ID.</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p><code>null</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_management_group_settings"></span> <a
href="#input_management_group_settings">management_group_settings</a></p></td>
<td style="text-align: left;"><p>The settings for the management groups.
This object configures the Azure Landing Zone management group
hierarchy, policies, and role assignments.</p>
<p>Properties: - <code>architecture_name</code> - (Optional) The name of
the architecture definition to use. Defaults to "alz_custom". -
<code>parent_management_group_id</code> - (Optional) The ID/name of the
parent management group (e.g., tenant ID or management group name). If
omitted, defaults to the tenant root group. - <code>location</code> -
(Required) The default Azure region for resources. -
<code>policy_default_values</code> - (Optional) A map of default values
for policy parameters. - <code>policy_assignments_to_modify</code> -
(Optional) Map of policy assignments to modify: -
<code>policy_assignments</code> - Map of policy assignment
modifications: - <code>enforcement_mode</code> - (Optional) The
enforcement mode for the policy assignment. - <code>identity</code> -
(Optional) The type of managed identity for the policy assignment. -
<code>identity_ids</code> - (Optional) List of user-assigned identity
resource IDs. - <code>parameters</code> - (Optional) Map of parameter
values for the policy assignment. - <code>non_compliance_messages</code>
- (Optional) Set of non-compliance messages: - <code>message</code> -
(Required) The non-compliance message. -
<code>policy_definition_reference_id</code> - (Optional) The policy
definition reference ID. - <code>resource_selectors</code> - (Optional)
List of resource selectors: - <code>name</code> - (Required) The name of
the resource selector. - <code>resource_selector_selectors</code> -
(Optional) List of selector criteria: - <code>kind</code> - (Required)
The kind of selector. - <code>in</code> - (Optional) Set of values to
include. - <code>not_in</code> - (Optional) Set of values to exclude. -
<code>overrides</code> - (Optional) List of policy overrides: -
<code>kind</code> - (Required) The kind of override. -
<code>value</code> - (Required) The override value. -
<code>override_selectors</code> - (Optional) List of override selectors:
- <code>kind</code> - (Required) The kind of selector. - <code>in</code>
- (Optional) Set of values to include. - <code>not_in</code> -
(Optional) Set of values to exclude. -
<code>management_group_hierarchy_settings</code> - (Optional) Settings
for the management group hierarchy: -
<code>default_management_group_name</code> - (Optional) The management
group where new subscriptions are placed. Defaults to "sandbox" per CAF
recommendation. - <code>require_authorization_for_group_creation</code>
- (Optional) Require authorization for management group creation.
Defaults to true. - <code>update_existing</code> - (Optional) Update
existing management groups. Defaults to false. - <code>partner_id</code>
- (Optional) The partner ID for Azure partner attribution. -
<code>retries</code> - (Optional) Retry configurations for various
resource types: - <code>management_groups</code>,
<code>role_definitions</code>, <code>role_assignments</code>,
<code>policy_definitions</code>, <code>policy_set_definitions</code>,
<code>policy_assignments</code>, <code>policy_role_assignments</code>,
<code>hierarchy_settings</code>, <code>subscription_placement</code> -
Each has the following retry settings: -
<code>error_message_regex</code> - (Optional) List of regex patterns to
match error messages for retry. - <code>interval_seconds</code> -
(Optional) The initial retry interval in seconds. -
<code>max_interval_seconds</code> - (Optional) The maximum retry
interval in seconds. - <code>multiplier</code> - (Optional) The
multiplier for exponential backoff. - <code>randomization_factor</code>
- (Optional) The randomization factor for retry intervals. -
<code>subscription_placement</code> - (Optional) Map of subscription
placement configurations: - <code>subscription_id</code> - (Required)
The subscription ID to place. - <code>management_group_name</code> -
(Required) The target management group name. - <code>timeouts</code> -
(Optional) Timeout configurations for various resource types: -
<code>management_group</code>, <code>role_definition</code>,
<code>role_assignment</code>, <code>policy_definition</code>,
<code>policy_set_definition</code>, <code>policy_assignment</code>,
<code>policy_role_assignment</code> - Each has the following timeout
settings: - <code>create</code> - (Optional) Timeout for create
operations. - <code>delete</code> - (Optional) Timeout for delete
operations. - <code>update</code> - (Optional) Timeout for update
operations. - <code>read</code> - (Optional) Timeout for read
operations. - <code>dependencies</code> - (Optional) Dependency
configurations: - <code>management_groups</code> - (Optional)
Dependencies for management group creation. -
<code>policy_role_assignments</code> - (Optional) Dependencies for
policy role assignments. - <code>policy_assignments</code> - (Optional)
Dependencies for policy assignments. -
<code>override_policy_definition_parameter_assign_permissions_set</code>
- (Optional) Set of policy definition parameters to assign permissions:
- <code>definition_name</code> - (Required) The policy definition name.
- <code>parameter_name</code> - (Required) The parameter name. -
<code>override_policy_definition_parameter_assign_permissions_unset</code>
- (Optional) Set of policy definition parameters to unset permissions: -
<code>definition_name</code> - (Required) The policy definition name. -
<code>parameter_name</code> - (Required) The parameter name. -
<code>management_group_role_assignments</code> - (Optional) Map of
management group role assignments: - <code>management_group_name</code>
- (Required) The target management group name. -
<code>role_definition_id_or_name</code> - (Required) The role definition
ID or name. - <code>principal_id</code> - (Required) The principal ID to
assign the role to. - <code>description</code> - (Optional) Description
of the role assignment. - <code>skip_service_principal_aad_check</code>
- (Optional) Skip service principal AAD check. Defaults to false. -
<code>condition</code> - (Optional) The condition for the role
assignment. - <code>condition_version</code> - (Optional) The condition
version. - <code>delegated_managed_identity_resource_id</code> -
(Optional) The delegated managed identity resource ID. -
<code>principal_type</code> - (Optional) The type of principal. -
<code>role_assignment_definition_lookup_enabled</code> - (Optional)
Enable role definition lookup for assignments. Defaults to true. -
<code>policy_assignment_non_compliance_message_settings</code> -
(Optional) Settings for policy non-compliance messages: -
<code>fallback_message_enabled</code> - (Optional) Enable fallback
messages. - <code>fallback_message</code> - (Optional) The fallback
message text. - <code>fallback_message_unsupported_assignments</code> -
(Optional) List of unsupported assignment names. -
<code>enforcement_mode_placeholder</code> - (Optional) Placeholder for
enforcement mode. - <code>enforced_replacement</code> - (Optional)
Replacement text for enforced mode. -
<code>not_enforced_replacement</code> - (Optional) Replacement text for
not enforced mode. - <code>role_assignment_name_use_random_uuid</code> -
(Optional) Use random UUID for role assignment names. Defaults to true.
- <code>subscription_placement_destroy_behavior</code> - (Optional)
Behavior when destroying subscription placement. Possible values:
"parent", "intermediate_root", "custom", "default". Defaults to
"default". -
<code>subscription_placement_destroy_custom_target_management_group_id</code>
- (Optional) Target management group ID when using "custom" destroy
behavior.</p>
<p>Details of the settings can be found in the module documentation at
<a
href="https://registry.terraform.io/modules/Azure/avm-ptn-alz">https://registry.terraform.io/modules/Azure/avm-ptn-alz</a></p></td>
<td style="text-align: left;"><pre><code>object({
    architecture_name            = optional(string, &quot;alz_custom&quot;)
    parent_management_group_id   = optional(string)
    location                     = optional(string)
    policy_default_values        = optional(any)
    policy_assignments_to_modify = optional(any)
    management_group_hierarchy_settings = optional(object({
      default_management_group_name            = optional(string, &quot;sandbox&quot;)
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
        create = optional(string, &quot;60m&quot;)
        delete = optional(string, &quot;60m&quot;)
        update = optional(string, &quot;60m&quot;)
        read   = optional(string, &quot;60m&quot;)
      }), {})
      role_definition = optional(object({
        create = optional(string, &quot;60m&quot;)
        delete = optional(string, &quot;60m&quot;)
        update = optional(string, &quot;60m&quot;)
        read   = optional(string, &quot;60m&quot;)
      }), {})
      role_assignment = optional(object({
        create = optional(string, &quot;60m&quot;)
        delete = optional(string, &quot;60m&quot;)
        update = optional(string, &quot;60m&quot;)
        read   = optional(string, &quot;60m&quot;)
      }), {})
      policy_definition = optional(object({
        create = optional(string, &quot;60m&quot;)
        delete = optional(string, &quot;60m&quot;)
        update = optional(string, &quot;60m&quot;)
        read   = optional(string, &quot;60m&quot;)
      }), {})
      policy_set_definition = optional(object({
        create = optional(string, &quot;60m&quot;)
        delete = optional(string, &quot;60m&quot;)
        update = optional(string, &quot;60m&quot;)
        read   = optional(string, &quot;60m&quot;)
      }), {})
      policy_assignment = optional(object({
        create = optional(string, &quot;60m&quot;)
        delete = optional(string, &quot;60m&quot;)
        update = optional(string, &quot;60m&quot;)
        read   = optional(string, &quot;60m&quot;)
      }), {})
      policy_role_assignment = optional(object({
        create = optional(string, &quot;60m&quot;)
        delete = optional(string, &quot;60m&quot;)
        update = optional(string, &quot;60m&quot;)
        read   = optional(string, &quot;60m&quot;)
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
    subscription_placement_destroy_behavior                          = optional(string, &quot;default&quot;)
    subscription_placement_destroy_custom_target_management_group_id = optional(string)
  })</code></pre></td>
<td style="text-align: left;"><p><code>null</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_management_groups_enabled"></span> <a
href="#input_management_groups_enabled">management_groups_enabled</a></p></td>
<td style="text-align: left;"><p>Enable or disable the deployment of
management groups.</p>
<p>When set to <code>true</code>, the management group hierarchy will be
created and configured according to the
<code>management_group_settings</code> variable. When set to
<code>false</code>, no management groups will be deployed.</p></td>
<td style="text-align: left;"><p><code>bool</code></p></td>
<td style="text-align: left;"><p><code>false</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_management_resource_settings"></span> <a
href="#input_management_resource_settings">management_resource_settings</a></p></td>
<td style="text-align: left;"><p>Configuration for Azure Landing Zone
management resources including Log Analytics and monitoring
solutions.</p>
<p>All settings are optional with sensible defaults. Set to
<code>{}</code> to deploy with defaults.</p>
<p>Properties: - <code>resource_group_name</code> - (Optional) Override
the resource group name. Defaults to naming convention. -
<code>log_analytics_workspace_name</code> - (Optional) Override the Log
Analytics workspace name. Defaults to naming convention. -
<code>data_collection_rules</code> - (Optional) Data collection rule
configurations: - <code>change_tracking</code> - Change tracking DCR.
Defaults to enabled. - <code>vm_insights</code> - VM insights DCR.
Defaults to enabled. - <code>defender_sql</code> - Defender for SQL DCR.
Defaults to disabled. - <code>log_analytics_solution_plans</code> -
(Optional) Solution plans to deploy to the workspace. -
<code>log_analytics_workspace_allow_resource_only_permissions</code> -
(Optional) Allow resource-only permissions. Defaults to true. -
<code>log_analytics_workspace_cmk_for_query_forced</code> - (Optional)
Force CMK for queries. -
<code>log_analytics_workspace_daily_quota_gb</code> - (Optional) Daily
ingestion quota in GB. Defaults to 10. Set to <code>-1</code> for
unlimited. -
<code>log_analytics_workspace_internet_ingestion_enabled</code> -
(Optional) Enable internet ingestion. Defaults to false. -
<code>log_analytics_workspace_internet_query_enabled</code> - (Optional)
Enable internet queries. Defaults to false. -
<code>log_analytics_workspace_local_authentication_enabled</code> -
(Optional) Enable local authentication. Defaults to false. -
<code>log_analytics_workspace_reservation_capacity_in_gb_per_day</code>
- (Optional) Reservation capacity for CapacityReservation SKU. -
<code>log_analytics_workspace_retention_in_days</code> - (Optional) Data
retention period in days. - <code>log_analytics_workspace_sku</code> -
(Optional) Workspace SKU (PerGB2018 or CapacityReservation). -
<code>tags</code> - (Optional) Tags for management resources. Merged
with root tags. - <code>timeouts</code> - (Optional) Timeout
configurations for data collection rules. -
<code>user_assigned_managed_identities</code> - (Optional) Managed
identity for Azure Monitor Agent. Defaults to enabled.</p>
<p><strong>Reliability:</strong> Log Analytics provides zone-redundant
data storage in supported regions. <strong>Cost:</strong> Use
CapacityReservation SKU for 15-25% savings on 100+ GB/day workloads.</p>
<p>Details of the settings can be found in the module documentation at
<a
href="https://registry.terraform.io/modules/Azure/avm-ptn-alz-management">https://registry.terraform.io/modules/Azure/avm-ptn-alz-management</a></p></td>
<td style="text-align: left;"><pre><code>object({
    resource_group_name          = optional(string)
    log_analytics_workspace_name = optional(string)
    data_collection_rules = optional(object({
      change_tracking = optional(object({
        enabled  = optional(bool, true)
        name     = optional(string, &quot;dcr-change-tracking&quot;)
        location = optional(string)
        tags     = optional(map(string))
      }), {})
      vm_insights = optional(object({
        enabled  = optional(bool, true)
        name     = optional(string, &quot;dcr-vm-insights&quot;)
        location = optional(string)
        tags     = optional(map(string))
      }), {})
      defender_sql = optional(object({
        enabled                                                = optional(bool, false)
        name                                                   = optional(string, &quot;dcr-defender-sql&quot;)
        location                                               = optional(string)
        tags                                                   = optional(map(string))
        enable_collection_of_sql_queries_for_security_research = optional(bool, false)
      }), {})
    }), {})
    log_analytics_solution_plans = optional(list(object({
      product   = string
      publisher = optional(string)
    })))
    log_analytics_workspace_allow_resource_only_permissions    = optional(bool, true)
    log_analytics_workspace_cmk_for_query_forced               = optional(bool)
    log_analytics_workspace_daily_quota_gb                     = optional(number, 10)
    log_analytics_workspace_internet_ingestion_enabled         = optional(bool, false)
    log_analytics_workspace_internet_query_enabled             = optional(bool, false)
    log_analytics_workspace_local_authentication_enabled       = optional(bool, false)
    log_analytics_workspace_reservation_capacity_in_gb_per_day = optional(number)
    log_analytics_workspace_retention_in_days                  = optional(number)
    log_analytics_workspace_sku                                = optional(string)
    tags                                                       = optional(map(string))
    timeouts = optional(object({
      data_collection_rule = optional(object({
        create = optional(string)
        delete = optional(string)
        update = optional(string)
        read   = optional(string)
      }))
    }), {})
    user_assigned_managed_identities = optional(object({
      ama = optional(object({
        enabled  = optional(bool, true)
        name     = optional(string, &quot;uai-ama&quot;)
        location = optional(string)
        tags     = optional(map(string))
      }), {})
    }), {})
  })</code></pre></td>
<td style="text-align: left;"><p><code>{}</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_management_resources_enabled"></span> <a
href="#input_management_resources_enabled">management_resources_enabled</a></p></td>
<td style="text-align: left;"><p>Enable or disable the deployment of
management resources.</p>
<p>When set to <code>true</code>, management resources such as Log
Analytics workspace, Data Collection Rules, and Managed Identities will
be deployed according to the <code>management_resource_settings</code>
variable. When set to <code>false</code>, no management resources will
be deployed.</p></td>
<td style="text-align: left;"><p><code>bool</code></p></td>
<td style="text-align: left;"><p><code>true</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_microsoft_defender_settings"></span> <a
href="#input_microsoft_defender_settings">microsoft_defender_settings</a></p></td>
<td style="text-align: left;"><p>Microsoft Defender for Cloud
configuration. Required when
<code>management_groups_enabled = true</code>. Can be omitted when
deploying only management resources.</p>
<ul>
<li><p><code>email_security_contact</code> - (Required) Email address
for security alerts.</p></li>
<li><p><code>export_resource_group_name</code> - (Optional) Resource
group name for ASC continuous export. Defaults to
"rg-asc-export".</p></li>
<li><p><code>defender_plans</code> - (Optional) Toggle individual
Defender plans. All default to false (Disabled). Set to true to enable
via DeployIfNotExists policy.</p></li>
<li><p><code>subfeatures</code> - (Optional) Toggle sub-features for
specific Defender plans. All default to false. These map to boolean
parameters in the Deploy-MDFC-Config-H224 policy assignment.</p></li>
</ul>
<p>Pricing overview (all plans default to disabled / no cost):</p>
<pre><code>Plan                              | Pricing Tier                | Billing Model
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
tvm_check                         | Cloud Workload Protection   | Sub-feature of Servers</code></pre>
<p>Sub-features are included in their parent plan at no additional cost,
except <code>storage_on_upload_malware_scanning</code> which incurs an
additional per-GB charge.</p>
<p>Full pricing details: <a
href="https://azure.microsoft.com/en-us/pricing/details/defender-for-cloud/#pricing">https://azure.microsoft.com/en-us/pricing/details/defender-for-cloud/#pricing</a></p>
<p>Example - enable Defender for Servers with vulnerability
assessments:</p>
<pre><code>microsoft_defender_settings = {
  email_security_contact = &quot;security@example.com&quot;
  defender_plans = {
    servers                           = true
    servers_vulnerability_assessments = true
  }
}</code></pre>
<p>Example - enable CSPM with agentless VM scanning:</p>
<pre><code>microsoft_defender_settings = {
  email_security_contact = &quot;security@example.com&quot;
  defender_plans = {
    cspm = true
  }
  subfeatures = {
    cspm_agentless_vm_scanning = true
  }
}</code></pre>
<p>Example - enable multiple plans:</p>
<pre><code>microsoft_defender_settings = {
  email_security_contact = &quot;security@example.com&quot;
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
}</code></pre></td>
<td style="text-align: left;"><pre><code>object({
    email_security_contact     = string
    export_resource_group_name = optional(string, &quot;rg-asc-export&quot;)
&#10;    # Defender plans - set to true to enable (deploys via DeployIfNotExists policy)
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
&#10;    # Sub-features for specific Defender plans
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
  })</code></pre></td>
<td style="text-align: left;"><p><code>null</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_monitoring_alerts"></span> <a
href="#input_monitoring_alerts">monitoring_alerts</a></p></td>
<td style="text-align: left;"><p>Health monitoring alerts for management
resources. Recommended for production.</p>
<ul>
<li><p><code>enabled</code> - Enable alerts. Auto-enabled when
action_group_id is provided.</p></li>
<li><p><code>action_group_id</code> - Action Group ID for notifications.
When set, alerts are auto-enabled.</p></li>
<li><p><code>ingestion_latency_threshold_seconds</code> - Latency
threshold (default: 120s).</p></li>
<li><p><code>data_ingest_threshold_gb</code> - Daily ingestion guardrail
(default: 100 GB).</p></li>
<li><p><code>search_availability_threshold_percent</code> - Search
availability threshold (default: 99%).</p></li>
<li><p><code>query_duration_threshold_ms</code> - Slow query duration
threshold (default: 15000 ms).</p></li>
<li><p><code>enable_query_failure_alerts</code> - Monitor query failures
(default: true).</p></li>
<li><p><code>query_failure_threshold</code> - Failure count to trigger
alert (default: 5).</p></li>
</ul></td>
<td style="text-align: left;"><pre><code>object({
    enabled                               = optional(bool)
    action_group_id                       = optional(string)
    ingestion_latency_threshold_seconds   = optional(number, 120)
    enable_query_failure_alerts           = optional(bool, true)
    query_failure_threshold               = optional(number, 5)
    data_ingest_threshold_gb              = optional(number, 100)
    search_availability_threshold_percent = optional(number, 99)
    query_duration_threshold_ms           = optional(number, 15000)
  })</code></pre></td>
<td style="text-align: left;"><p><code>{}</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_region_geography"></span> <a
href="#input_region_geography">region_geography</a></p></td>
<td style="text-align: left;"><p>Filter available regions by geography.
Common values: 'United Kingdom', 'Europe', 'United States', 'Asia
Pacific'. Set to null for all geographies.</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p><code>null</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_region_recommended_filter"></span> <a
href="#input_region_recommended_filter">region_recommended_filter</a></p></td>
<td style="text-align: left;"><p>Filter by Microsoft-recommended
regions. Set to true for recommended only, false for non-recommended
only, or null (default) for all regions.</p></td>
<td style="text-align: left;"><p><code>bool</code></p></td>
<td style="text-align: left;"><p><code>null</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_resource_group_lock_enabled"></span> <a
href="#input_resource_group_lock_enabled">resource_group_lock_enabled</a></p></td>
<td style="text-align: left;"><p>Enable CanNotDelete lock on all
resource groups. Set to false before running terraform destroy.</p></td>
<td style="text-align: left;"><p><code>bool</code></p></td>
<td style="text-align: left;"><p><code>true</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span
id="input_security_subscription_id"></span> <a
href="#input_security_subscription_id">security_subscription_id</a></p></td>
<td style="text-align: left;"><p>(Optional) Subscription ID to place in
the 'security' management group. Only used when
<code>management_groups_enabled = true</code>.</p></td>
<td style="text-align: left;"><p><code>string</code></p></td>
<td style="text-align: left;"><p><code>null</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><p><span
id="input_skip_subscription_placement"></span> <a
href="#input_skip_subscription_placement">skip_subscription_placement</a></p></td>
<td style="text-align: left;"><p>Skip platform subscription validation
and placement.</p>
<p>When <code>true</code>: - Skips connectivity_subscription_id
validation - Only places management_subscription_id into the management
group - Allows testing the full ALZ deployment with a single
subscription</p>
<p>Useful for development/testing when you only have a management
subscription. Not recommended for production deployments.</p></td>
<td style="text-align: left;"><p><code>bool</code></p></td>
<td style="text-align: left;"><p><code>false</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><span id="input_tags"></span> <a
href="#input_tags">tags</a></p></td>
<td style="text-align: left;"><p>(Optional) Tags applied to all
resources.</p></td>
<td style="text-align: left;"><p><code>map(string)</code></p></td>
<td style="text-align: left;"><p><code>{}</code></p></td>
<td style="text-align: left;"><p>no</p></td>
</tr>
</tbody>
</table>

## Outputs

| Name                                                                                                                        | Description                                        |
|-----------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------|
| <span id="output_log_analytics_workspace_guid"></span> [log_analytics_workspace_guid](#output_log_analytics_workspace_guid) | The workspace GUID of the log analytics workspace. |
| <span id="output_log_analytics_workspace_id"></span> [log_analytics_workspace_id](#output_log_analytics_workspace_id)       | The resource ID of the log analytics workspace.    |

<!-- END_TF_DOCS -->

## Support

For issues, questions, or contributions related to this module, please
contact the Ensono Stacks team.

## License

Copyright (c) 2026 Ensono

This project is licensed under the MIT License.
