locals {
  # Keep visual identity consistent across the five operational sections.
  kubernetes_section_colors = ["vivid_blue", "vivid_purple", "vivid_orange", "vivid_green", "vivid_pink"]
  kubernetes_chart_palettes = ["cool", "dog_classic", "warm", "cool", "dog_classic"]
  kubernetes_summary = [
    {
      "title" : "Nodes",
      "queries" : [
        "sum:kubernetes_state.node.count{$cluster}"
      ]
    },
    {
      "title" : "Pods",
      "queries" : [
        "sum:kubernetes_state.pod.count{$cluster,$namespace}"
      ]
    },
    {
      "title" : "Running containers",
      "queries" : [
        "sum:kubernetes_state.container.running{$cluster,$namespace}"
      ]
    },
    {
      "title" : "Unavailable deployment replicas",
      "queries" : [
        "sum:kubernetes_state.deployment.replicas_unavailable{$cluster,$namespace}"
      ]
    },
    {
      "title" : "Unschedulable pods",
      "queries" : [
        "sum:kubernetes_state.pod.unschedulable{$cluster,$namespace}"
      ]
    },
    {
      "title" : "Pending PVCs",
      "queries" : [
        "sum:kubernetes_state.persistentvolumeclaim.status{$cluster,$namespace,$storageclass,phase:pending}"
      ]
    }
  ]
  kubernetes_sections = [
    {
      "title" : "Nodes and cluster capacity \u2014 cluster filter only",
      "charts" : [
        {
          "title" : "Node readiness (1 = ready)",
          "queries" : [
            "max:kubernetes_state.node.by_condition{$cluster,condition:ready,status:true} by {node}"
          ]
        },
        {
          "title" : "Node pressure (1 = pressure)",
          "queries" : [
            "max:kubernetes_state.node.by_condition{$cluster,!condition:ready,status:true} by {node,condition}"
          ]
        },
        {
          "title" : "Allocatable CPU cores by node",
          "queries" : [
            "max:kubernetes_state.node.cpu_allocatable{$cluster} by {node}"
          ]
        },
        {
          "title" : "Allocatable memory bytes by node",
          "queries" : [
            "max:kubernetes_state.node.memory_allocatable{$cluster} by {node}"
          ]
        },
        {
          "title" : "Pod capacity by node",
          "queries" : [
            "max:kubernetes_state.node.pods_allocatable{$cluster} by {node}"
          ]
        },
        {
          "title" : "Pods by node",
          "queries" : [
            "sum:kubernetes_state.pod.count{$cluster} by {node}"
          ]
        }
      ]
    },
    {
      "title" : "Workloads \u2014 desired vs ready replicas",
      "charts" : [
        {
          "title" : "Deployment desired / ready / available",
          "queries" : [
            "sum:kubernetes_state.deployment.replicas_desired{$cluster,$namespace} by {kube_namespace,kube_deployment}",
            "sum:kubernetes_state.deployment.replicas_ready{$cluster,$namespace} by {kube_namespace,kube_deployment}",
            "sum:kubernetes_state.deployment.replicas_available{$cluster,$namespace} by {kube_namespace,kube_deployment}"
          ]
        },
        {
          "title" : "Deployment unavailable replicas",
          "queries" : [
            "sum:kubernetes_state.deployment.replicas_unavailable{$cluster,$namespace} by {kube_namespace,kube_deployment}"
          ]
        },
        {
          "title" : "StatefulSet desired / ready / updated",
          "queries" : [
            "sum:kubernetes_state.statefulset.replicas_desired{$cluster,$namespace} by {kube_namespace,kube_stateful_set}",
            "sum:kubernetes_state.statefulset.replicas_ready{$cluster,$namespace} by {kube_namespace,kube_stateful_set}",
            "sum:kubernetes_state.statefulset.replicas_updated{$cluster,$namespace} by {kube_namespace,kube_stateful_set}"
          ]
        },
        {
          "title" : "DaemonSet desired / ready / unavailable",
          "queries" : [
            "sum:kubernetes_state.daemonset.desired{$cluster,$namespace} by {kube_namespace,kube_daemon_set}",
            "sum:kubernetes_state.daemonset.ready{$cluster,$namespace} by {kube_namespace,kube_daemon_set}",
            "sum:kubernetes_state.daemonset.daemons_unavailable{$cluster,$namespace} by {kube_namespace,kube_daemon_set}"
          ]
        },
        {
          "title" : "HPA current / desired / maximum (including KEDA HPAs)",
          "queries" : [
            "sum:kubernetes_state.hpa.current_replicas{$cluster,$namespace} by {kube_namespace,horizontalpodautoscaler}",
            "sum:kubernetes_state.hpa.desired_replicas{$cluster,$namespace} by {kube_namespace,horizontalpodautoscaler}",
            "sum:kubernetes_state.hpa.max_replicas{$cluster,$namespace} by {kube_namespace,horizontalpodautoscaler}"
          ]
        },
        {
          "title" : "Failed job pods",
          "queries" : [
            "sum:kubernetes_state.job.failed{$cluster,$namespace} by {kube_namespace,kube_job}"
          ]
        },
        {
          "title" : "CronJob seconds since last successful execution",
          "queries" : [
            "max:kubernetes_state.cronjob.duration_since_last_successful{$cluster,$namespace} by {kube_namespace,kube_cronjob}"
          ]
        },
        {
          "title" : "PDB healthy / desired pods",
          "queries" : [
            "sum:kubernetes_state.pdb.pods_healthy{$cluster,$namespace} by {kube_namespace,poddisruptionbudget}",
            "sum:kubernetes_state.pdb.pods_desired{$cluster,$namespace} by {kube_namespace,poddisruptionbudget}"
          ]
        }
      ]
    },
    {
      "title" : "Pods and containers \u2014 pod filter applies",
      "charts" : [
        {
          "title" : "Pod phases",
          "queries" : [
            "sum:kubernetes_state.pod.status_phase{$cluster,$namespace,$pod} by {kube_namespace,pod_phase}"
          ]
        },
        {
          "title" : "Unschedulable pods",
          "queries" : [
            "max:kubernetes_state.pod.unschedulable{$cluster,$namespace,$pod} by {kube_namespace,pod_name}"
          ]
        },
        {
          "title" : "Container readiness (1 = ready)",
          "queries" : [
            "max:kubernetes_state.container.ready{$cluster,$namespace,$pod} by {kube_namespace,pod_name,kube_container_name}"
          ]
        },
        {
          "title" : "Container waiting reasons \u2014 CrashLoop / image pull",
          "queries" : [
            "sum:kubernetes_state.container.status_report.count.waiting{$cluster,$namespace,$pod} by {kube_namespace,pod_name,reason}"
          ]
        },
        {
          "title" : "Container termination reasons \u2014 includes OOMKilled",
          "queries" : [
            "sum:kubernetes_state.container.status_report.count.terminated{$cluster,$namespace,$pod} by {kube_namespace,pod_name,reason}"
          ]
        },
        {
          "title" : "Container lifetime restarts (cumulative gauge)",
          "queries" : [
            "max:kubernetes_state.container.restarts{$cluster,$namespace,$pod} by {kube_namespace,pod_name,kube_container_name}"
          ]
        },
        {
          "title" : "Container CPU usage (cores)",
          "queries" : [
            "sum:kubernetes.cpu.usage.total{$cluster,$namespace,$pod} by {kube_namespace,pod_name,kube_container_name} / 1000000000"
          ]
        },
        {
          "title" : "Container memory working set (bytes)",
          "queries" : [
            "sum:kubernetes.memory.working_set{$cluster,$namespace,$pod} by {kube_namespace,pod_name,kube_container_name}"
          ]
        },
        {
          "title" : "Container CPU requests / limits (cores)",
          "queries" : [
            "max:kubernetes_state.container.cpu_requested{$cluster,$namespace,$pod} by {kube_namespace,pod_name,kube_container_name}",
            "max:kubernetes_state.container.cpu_limit{$cluster,$namespace,$pod} by {kube_namespace,pod_name,kube_container_name}"
          ]
        },
        {
          "title" : "Container memory requests / limits (bytes)",
          "queries" : [
            "max:kubernetes_state.container.memory_requested{$cluster,$namespace,$pod} by {kube_namespace,pod_name,kube_container_name}",
            "max:kubernetes_state.container.memory_limit{$cluster,$namespace,$pod} by {kube_namespace,pod_name,kube_container_name}"
          ]
        }
      ]
    },
    {
      "title" : "Storage \u2014 gp3, PVC binding and filesystem usage",
      "charts" : [
        {
          "title" : "PVC phases by storage class",
          "queries" : [
            "sum:kubernetes_state.persistentvolumeclaim.status{$cluster,$namespace,$storageclass} by {kube_namespace,storageclass,phase}"
          ]
        },
        {
          "title" : "Pending PVCs by claim",
          "queries" : [
            "max:kubernetes_state.persistentvolumeclaim.status{$cluster,$namespace,$storageclass,phase:pending} by {kube_namespace,persistentvolumeclaim}"
          ]
        },
        {
          "title" : "Requested PVC capacity (bytes)",
          "queries" : [
            "max:kubernetes_state.persistentvolumeclaim.request_storage{$cluster,$namespace,$storageclass} by {kube_namespace,persistentvolumeclaim}"
          ]
        },
        {
          "title" : "PV phases \u2014 cluster-wide",
          "queries" : [
            "sum:kubernetes_state.persistentvolume.by_phase{$cluster,$storageclass} by {storageclass,phase}"
          ]
        },
        {
          "title" : "PV capacity (bytes) \u2014 cluster-wide",
          "queries" : [
            "max:kubernetes_state.persistentvolume.capacity{$cluster,$storageclass} by {persistentvolume,storageclass}"
          ]
        },
        {
          "title" : "Mounted PVC used / capacity bytes \u2014 all storage classes",
          "queries" : [
            "max:kubernetes.kubelet.volume.stats.used_bytes{$cluster,$namespace} by {kube_namespace,persistentvolumeclaim}",
            "max:kubernetes.kubelet.volume.stats.capacity_bytes{$cluster,$namespace} by {kube_namespace,persistentvolumeclaim}"
          ]
        },
        {
          "title" : "Mounted PVC usage (%) \u2014 all storage classes",
          "queries" : [
            "100 * max:kubernetes.kubelet.volume.stats.used_bytes{$cluster,$namespace} by {kube_namespace,persistentvolumeclaim} / max:kubernetes.kubelet.volume.stats.capacity_bytes{$cluster,$namespace} by {kube_namespace,persistentvolumeclaim}"
          ]
        },
        {
          "title" : "Mounted PVC inode usage (%) \u2014 all storage classes",
          "queries" : [
            "100 * max:kubernetes.kubelet.volume.stats.inodes_used{$cluster,$namespace} by {kube_namespace,persistentvolumeclaim} / max:kubernetes.kubelet.volume.stats.inodes{$cluster,$namespace} by {kube_namespace,persistentvolumeclaim}"
          ]
        },
        {
          "title" : "Pod ephemeral storage usage (bytes)",
          "queries" : [
            "max:kubernetes.ephemeral_storage.usage{$cluster,$namespace} by {kube_namespace,pod_name}"
          ]
        },
        {
          "title" : "Container filesystem usage (bytes)",
          "queries" : [
            "sum:kubernetes.filesystem.usage{$cluster,$namespace} by {kube_namespace,pod_name,kube_container_name}"
          ]
        }
      ]
    },
    {
      "title" : "Platform add-ons \u2014 all platform namespaces",
      "charts" : [
        {
          "title" : "KEDA, Karpenter, Istio, Autoscaler and Datadog desired / ready",
          "queries" : [
            "sum:kubernetes_state.deployment.replicas_desired{$cluster AND kube_namespace IN (keda,karpenter,istio-system,istio-ingress,cluster-autoscaler,datadog,kube-system,external-dns)} by {kube_namespace,kube_deployment}",
            "sum:kubernetes_state.deployment.replicas_ready{$cluster AND kube_namespace IN (keda,karpenter,istio-system,istio-ingress,cluster-autoscaler,datadog,kube-system,external-dns)} by {kube_namespace,kube_deployment}"
          ]
        },
        {
          "title" : "EBS CSI, networking and Agent DaemonSets desired / ready",
          "queries" : [
            "sum:kubernetes_state.daemonset.desired{$cluster AND kube_namespace IN (kube-system,datadog)} by {kube_namespace,kube_daemon_set}",
            "sum:kubernetes_state.daemonset.ready{$cluster AND kube_namespace IN (kube-system,datadog)} by {kube_namespace,kube_daemon_set}"
          ]
        }
      ]
    }
  ]
}

resource "datadog_dashboard" "kubernetes" {
  title       = "EKS | ${var.cluster_name} | ${var.environment}"
  description = "Operational overview: nodes, workloads, pods, containers, PVC/PV storage and platform add-ons. No data is not a healthy zero. Node and platform panels use only the cluster filter. Volume usage requires mounted filesystem PVCs and CSI volume statistics."
  layout_type = "ordered"
  reflow_type = "auto"

  template_variable {
    name    = "cluster"
    prefix  = "kube_cluster_name"
    default = var.cluster_name
  }
  template_variable {
    name    = "namespace"
    prefix  = "kube_namespace"
    default = "*"
  }
  template_variable {
    name    = "pod"
    prefix  = "pod_name"
    default = "*"
  }
  template_variable {
    name    = "storageclass"
    prefix  = "storageclass"
    default = "*"
  }

  widget {
    note_definition {
      content          = "## EKS operations\nStart with unavailable replicas, unschedulable pods and Pending PVCs; then inspect the matching workload and container reason. Namespace filters apply to workload panels; pod filters apply to the pod/container section. Nodes and platform add-ons remain cluster-wide. Storage-class filters apply to PVC/PV metadata, not kubelet usage. Empty graphs can mean missing collection or no matching resources. Restarts are lifetime totals, not new restarts in the selected window."
      background_color = "blue"
      font_size        = "14"
      text_align       = "left"
      show_tick        = false
    }
  }

  dynamic "widget" {
    for_each = local.kubernetes_summary
    iterator = summary
    content {
      query_value_definition {
        title      = summary.value.title
        autoscale  = true
        precision  = 0
        text_align = "center"
        title_size = "16"
        timeseries_background {
          type = "area"
        }
        request {
          q          = summary.value.queries[0]
          aggregator = "last"
          # Inventory is blue when present; failure counts turn red above zero.
          conditional_formats {
            comparator = ">"
            value      = 0
            palette    = summary.key < 3 ? "blue" : "white_on_red"
          }
          conditional_formats {
            comparator = "="
            value      = 0
            palette    = summary.key < 3 ? "white_on_yellow" : "white_on_green"
          }
        }
      }
    }
  }

  widget {
    event_stream_definition {
      title      = "Kubernetes events — scheduling, mounts and provisioning"
      query      = "sources:kubernetes $cluster"
      event_size = "s"
    }
  }

  dynamic "widget" {
    for_each = local.kubernetes_sections
    iterator = section
    content {
      group_definition {
        title            = section.value.title
        layout_type      = "ordered"
        background_color = local.kubernetes_section_colors[section.key]
        show_title       = true
        dynamic "widget" {
          for_each = section.value.charts
          iterator = chart
          content {
            timeseries_definition {
              title       = chart.value.title
              show_legend = true
              dynamic "request" {
                for_each = chart.value.queries
                iterator = query
                content {
                  q = query.value
                  # Filled single-series charts; bars for failures and phases.
                  display_type = can(regex("(?i)phase|pending|unschedulable|unavailable|waiting|termination|failed", chart.value.title)) ? "bars" : (length(chart.value.queries) == 1 ? "area" : "line")
                  style {
                    palette    = local.kubernetes_chart_palettes[section.key]
                    line_type  = query.key == 0 && length(chart.value.queries) > 1 ? "dashed" : "solid"
                    line_width = "thick"
                  }
                }
              }
              dynamic "marker" {
                # Capacity thresholds are visual guides, not alert monitors.
                for_each = can(regex("usage \\(%%?\\)", chart.value.title)) ? [80, 90] : []
                content {
                  value        = "y = ${marker.value}"
                  label        = marker.value == 80 ? "Warning: 80%" : "Critical: 90%"
                  display_type = marker.value == 80 ? "warning dashed" : "error bold"
                }
              }
              yaxis {
                include_zero = true
                scale        = "linear"
              }
            }
          }
        }
      }
    }
  }
}

output "kubernetes_dashboard_url" {
  description = "Datadog Kubernetes operations dashboard"
  value       = datadog_dashboard.kubernetes.url
}
