variable "monitoring_alerts" {
  type = object({
    enabled                             = optional(bool)
    action_group_id                     = optional(string)
    ingestion_latency_threshold_seconds = optional(number, 120)
    enable_query_failure_alerts         = optional(bool, true)
    query_failure_threshold             = optional(number, 5)
  })
  default     = {}
  description = <<-DESCRIPTION
    Health monitoring alerts for management resources. Recommended for production.

    - `enabled` - Enable alerts. Auto-enabled when action_group_id is provided.
    - `action_group_id` - Action Group ID for notifications. When set, alerts are auto-enabled.
    - `ingestion_latency_threshold_seconds` - Latency threshold (default: 120s).
    - `storage_availability_threshold` - Availability threshold (default: 99.9%).
    - `enable_query_failure_alerts` - Monitor query failures (default: true).
    - `query_failure_threshold` - Failure count to trigger alert (default: 5).
  DESCRIPTION

  validation {
    condition = (
      var.monitoring_alerts.ingestion_latency_threshold_seconds >= 30 &&
      var.monitoring_alerts.ingestion_latency_threshold_seconds <= 600
    )
    error_message = "ingestion_latency_threshold_seconds must be between 30 and 600 seconds."
  }

  validation {
    condition = (
      var.monitoring_alerts.query_failure_threshold >= 1 &&
      var.monitoring_alerts.query_failure_threshold <= 100
    )
    error_message = "query_failure_threshold must be between 1 and 100."
  }
}
