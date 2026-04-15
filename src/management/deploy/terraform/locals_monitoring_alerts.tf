locals {
  # Auto-enable alerts when action_group_id is provided, unless explicitly disabled
  monitoring_alerts_enabled = coalesce(var.monitoring_alerts.enabled, var.monitoring_alerts.action_group_id != null)

  # Convert data ingestion threshold (GB) to bytes for metric alert comparisons
  monitoring_alerts_ingest_threshold_bytes = coalesce(var.monitoring_alerts.data_ingest_threshold_gb, 0) * pow(1024, 3)
}
