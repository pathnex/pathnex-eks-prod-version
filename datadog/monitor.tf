resource "datadog_monitor" "network_traffic" {
    draft_status             = "published"
    escalation_message       = null
    evaluation_delay         = 0
    group_retention_duration = null
    include_tags             = false
    locked                   = false
    message                  = <<-EOT
        ## 🚨 What's happening

        High **incoming network traffic** detected on host {{host.name}}.

        This means the host is receiving a sustained high volume of data — with the 15-minute average of `system.net.bytes_rcvd` exceeding **80 MB/min**. This typically indicates heavy data ingestion, large transfers, or inefficient service communication patterns.

        ***

        ## 📈 Impact

        If network traffic remains elevated, it can lead to:

        -   **Bandwidth saturation**, packet loss, or throttling
        -   **Latency or degraded performance** in network-bound services
        -   **Slow log shipping**, delayed data pipelines, or failed syncs
        -   **Contended resources** in multi-tenant environments (e.g., containers)

        This may impact the host's ability to serve real-time workloads or maintain timely communication with external systems, APIs, or databases.

        ***

        ## 🛠️ Runbook

        ### Initial Troubleshooting Steps

        1.  **Identify the affected host** from the alert.

        2.  Open [**Infrastructure > Host Details**](/infrastructure) in Datadog.

        3.  In the **Metrics** tab, examine:

            -   `system.net.bytes_rcvd`, `system.net.bytes_sent`
            -   Interface metrics (`system.net.iface.*`)

        4.  Check application logs for unexpected ingest behavior.

        5.  Use tools like `iftop`, `nload`, or `netstat` to inspect top inbound connections.

        6.  (If needed) SSH into the host and run:

            ```
            bash
            CopyEdit
            sudo iftop -i <interface>
            ```

        ***

        ### Cause and Resolution

        | Cause                                           | Resolution                                                  |
        | ----------------------------------------------- | ----------------------------------------------------------- |
        | Large file transfers (e.g., backups, ingestion) | Schedule during off-peak hours or limit transfer rate       |
        | Misconfigured agents or services                | Review configs and reduce polling or payload size           |
        | Unexpected traffic spike or DDoS                | Block IPs, apply rate limits, or enable network protections |
        | Log/metric flooding from other systems          | Throttle integrations or export rates                       |

        ***

        ### 🔗 Related links

        -   [Host Map](/infrastructure/map)
        -   [Live Processes](/process)
        -   [System Dashboards](/dashboard/lists)
        -   [Monitor Documentation](https://docs.datadoghq.com/monitors/)
        -   [Logs](/logs?query=host:{{host.name}})
        -   [Infrastructure](/infrastructure/hosts?scope=host:{{host.name}})
        -   [Metrics Explorer (system.net.bytes_rcvd)](/metric/explorer?exp_metric=system.net.bytes_rcvd&exp_scope=host:{{host.name}}&exp_agg=avg&exp_type=line)

        ***

        ### 📣 Who should be notified?

        Please assign the appropriate notification handle for this alert (e.g., `@slack-networking`, `@pagerduty-platform-oncall`):\
        `@your-team-handle`
    EOT
    name                     = "Network traffic (received) is high on host {{host.name}}"
    new_group_delay          = 0
    new_host_delay           = 300
    no_data_timeframe        = 0
    notification_preset_name = null
    notify_audit             = false
    notify_by                = []
    notify_no_data           = false
    on_missing_data          = null
    priority                 = null
    query                    = "avg(last_15m):avg:system.net.bytes_rcvd{*} by {host} / (1024 * 1024 * 1024) > 0.08"
    renotify_interval        = 0
    renotify_occurrences     = 0
    require_full_window      = false
    tags                     = [
        "integration:host",
        "monitor_pack:host",
    ]
    timeout_h                = 0
    type                     = "query alert"

    monitor_thresholds {
        critical          = "0.08"
        critical_recovery = null
        ok                = null
        unknown           = null
        warning           = null
        warning_recovery  = null
    }
}
