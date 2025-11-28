# install_prometheus

Deploys Prometheus metrics server and kube-state-metrics for Kubernetes monitoring.

## Requirements

- Kubernetes cluster with kubectl configured
- Longhorn storage class (or modify `prometheus_storage_class`)

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `prometheus_namespace` | `monitoring` | Kubernetes namespace |
| `prometheus_image` | `prom/prometheus:v3.1.0` | Prometheus container image |
| `kube_state_metrics_image` | `registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.15.0` | kube-state-metrics image |
| `prometheus_cpu_request` | `200m` | Prometheus CPU request |
| `prometheus_cpu_limit` | `1000m` | Prometheus CPU limit |
| `prometheus_memory_request` | `512Mi` | Prometheus memory request |
| `prometheus_memory_limit` | `1Gi` | Prometheus memory limit |
| `ksm_cpu_request` | `100m` | kube-state-metrics CPU request |
| `ksm_cpu_limit` | `200m` | kube-state-metrics CPU limit |
| `ksm_memory_request` | `128Mi` | kube-state-metrics memory request |
| `ksm_memory_limit` | `256Mi` | kube-state-metrics memory limit |
| `prometheus_storage_size` | `20Gi` | PVC storage size |
| `prometheus_storage_class` | `longhorn` | Storage class |
| `prometheus_retention_days` | `30d` | Metrics retention period |
| `prometheus_ingress_enabled` | `true` | Enable Traefik IngressRoute |
| `prometheus_ingress_host` | `prometheus.corp.mulliken.net` | Ingress hostname |

## Usage

```yaml
- hosts: localhost
  roles:
    - install_prometheus
```

## What's Scraped

The default configuration scrapes:

- Prometheus itself
- Node Exporter (system metrics)
- kube-state-metrics (Kubernetes object metrics)
- Kubernetes API Server
- Kubernetes nodes
- cAdvisor (container metrics)
- Any pod with `prometheus.io/scrape: "true"` annotation

## Access

- **Ingress**: https://prometheus.corp.mulliken.net
- **Port-forward**: `kubectl -n monitoring port-forward svc/prometheus 9090:9090`
- **Internal**: http://prometheus.monitoring.svc.cluster.local:9090

## Dependencies

None
