# EKS operations dashboard

`datadog.yaml` configures the existing Datadog Operator's Agent resource. `dash.tf`
manages the existing `datadog_dashboard.kubernetes` Terraform resource, retaining
its resource address so an existing managed dashboard can be updated in place.

From this directory:

```sh
kubectl apply --dry-run=server -f datadog.yaml
kubectl apply -f datadog.yaml
terraform init
terraform plan
terraform apply
terraform output -raw kubernetes_dashboard_url
```

The Operator, its DatadogAgent CRD, the `datadog` namespace and the existing
`datadog-secret` API-key secret must already exist. Terraform uses the existing
SSM API/application-key configuration in `provider.tf`. It requires dashboard
write permissions. These commands use your currently selected Kubernetes context
and AWS credentials; check they point to the intended EKS cluster.

The Agent's cluster name and Terraform's `cluster_name` must match. Both currently
use `pathnex-sep-2026`; the dashboard selects the `kube_cluster_name` tag, not
`cluster_name`.

## Coverage and filters

- Six overview values, 36 charts in five groups, and a Kubernetes event stream.
- Nodes: readiness, pressure, allocatable CPU/memory and pod capacity.
- Workloads: Deployments, StatefulSets, DaemonSets, HPA/KEDA scaling, Jobs,
  CronJobs and disruption budgets.
- Pods/containers: phases, scheduling failures, waiting/termination reasons,
  lifetime restart counts, CPU cores, memory working set, requests and limits.
- Storage: PVC binding, storage classes including gp3, requested capacity, PV
  state/capacity, mounted filesystem usage, inode usage and ephemeral storage.
- Platform: Karpenter, KEDA, Istio, Cluster Autoscaler, Datadog, external-dns and
  core EKS controller/DaemonSet replica health, including old namespaces during migration.

Namespace selection applies to namespaced panels; pod selection applies only to
the pod/container section. Node and platform panels always show the selected
cluster. Storage-class selection applies only to PVC/PV metadata because kubelet
volume metrics do not consistently have a storage-class tag. PVs are cluster scoped.

## Reading and validating the dashboard

Allow several collection intervals after applying the Agent configuration.
Check Agent/Cluster Agent status if `kubernetes_state.*` or kubelet metrics are
absent. Pod-level check tags are enabled with `checksTagCardinality: orchestrator`.
Higher tag cardinality increases the number of metric series.

Empty panels do not prove health: an absent StatefulSet, HPA or PVC can legitimately
produce no data. Missing Agent collection can look the same. Restart counts are
cumulative for each container's lifetime, not restarts within the chart window.
CPU usage is converted from nanocores to cores; memory and storage remain bytes.

PVC filesystem statistics require mounted filesystem volumes and a CSI driver
that supplies volume statistics. Pending/unmounted PVCs and raw block volumes may
have metadata but no usage metrics. AWS EBS IOPS, latency and throughput require
the Datadog AWS/CloudWatch EBS integration; this dashboard does not configure it.
Platform replica health is included, but Istio request latency, KEDA trigger
errors and Karpenter provisioning internals require their separate integrations.

This dashboard visualizes health; it does not add paging/alert monitors. The
existing `monitor.tf` network monitor is unchanged. Local Terraform validation
does not verify live metric availability or Datadog API query acceptance.

References: [Kubernetes State Core](https://docs.datadoghq.com/integrations/kubernetes_state_core/),
[Kubelet metrics](https://docs.datadoghq.com/integrations/kubelet/),
[Operator configuration](https://github.com/DataDog/datadog-operator/blob/main/docs/configuration.v2alpha1.md).
