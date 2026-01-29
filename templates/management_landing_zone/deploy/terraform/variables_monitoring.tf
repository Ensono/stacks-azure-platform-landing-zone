variable "monitoring_alerts" {
  type = object({
    enabled                               = optional(bool)
    action_group_id                       = optional(string)
    ingestion_latency_threshold_seconds   = optional(number, 120)
    enable_query_failure_alerts           = optional(bool, true)
    query_failure_threshold               = optional(number, 5)
    data_ingest_threshold_gb              = optional(number, 100)
    search_availability_threshold_percent = optional(number, 99)
    query_duration_threshold_ms           = optional(number, 15000)
  })
  default     = {}
  description = <<-DESCRIPTION
    Health monitoring alerts for management resources. Recommended for production.

    - `enabled` - Enable alerts. Auto-enabled when action_group_id is provided.
    - `action_group_id` - Action Group ID for notifications. When set, alerts are auto-enabled.
    - `ingestion_latency_threshold_seconds` - Latency threshold (default: 120s).
    - `data_ingest_threshold_gb` - Daily ingestion guardrail (default: 100 GB).
    - `search_availability_threshold_percent` - Search availability threshold (default: 99%).
    - `query_duration_threshold_ms` - Slow query duration threshold (default: 15000 ms).
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

  validation {
    condition = (
      var.monitoring_alerts.data_ingest_threshold_gb > 0 &&
      var.monitoring_alerts.data_ingest_threshold_gb <= 10000
    )
    error_message = "data_ingest_threshold_gb must be between 1 and 10000."
  }

  validation {
    condition = (
      var.monitoring_alerts.search_availability_threshold_percent >= 90 &&
      var.monitoring_alerts.search_availability_threshold_percent <= 100
    )
    error_message = "search_availability_threshold_percent must be between 90 and 100."
  }

  validation {
    condition = (
      var.monitoring_alerts.query_duration_threshold_ms >= 1000 &&
      var.monitoring_alerts.query_duration_threshold_ms <= 600000
    )
    error_message = "query_duration_threshold_ms must be between 1000 and 600000."
  }
}
