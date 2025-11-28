# install_victoria_metrics

Deploys Victoria Metrics - a lightweight, high-performance Prometheus-compatible monitoring solution.

## Why Victoria Metrics?

Victoria Metrics uses significantly fewer resources than Prometheus while maintaining full compatibility:

| Metric | Prometheus | Victoria Metrics |
|--------|-----------|------------------|
| CPU Request | 200m | 50m |
| CPU Limit | 1000m | 200m |
| Memory Request | 512Mi | 64Mi |
| Memory Limit | 1Gi | 256Mi |
| PromQL Support | Yes | Yes |
| Grafana Compatible | Yes | Yes |

## Requirements

- Kubernetes cluster with kubectl configured
- Longhorn storage class (or modify `victoria_metrics_storage_class`)

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `victoria_metrics_namespace` | `monitoring` | Kubernetes namespace |
| `victoria_metrics_image` | `victoriametrics/victoria-metrics:v1.106.1` | Victoria Metrics image |
| `victoria_metrics_cpu_request` | `50m` | CPU request |
| `victoria_metrics_cpu_limit` | `200m` | CPU limit |
| `victoria_metrics_memory_request` | `64Mi` | Memory request |
| `victoria_metrics_memory_limit` | `256Mi` | Memory limit |
| `victoria_metrics_storage_size` | `20Gi` | PVC size |
| `victoria_metrics_storage_class` | `longhorn` | Storage class |
| `victoria_metrics_retention_period` | `30d` | Data retention period |
| `victoria_metrics_ingress_enabled` | `true` | Enable Traefik IngressRoute |
| `victoria_metrics_ingress_host` | `prometheus.corp.mulliken.net` | Ingress hostname |
| `kube_state_metrics_enabled` | `true` | Deploy kube-state-metrics |

## Usage

```yaml
- hosts: localhost
  roles:
    - install_victoria_metrics
```

## Access

- **Ingress**: https://prometheus.corp.mulliken.net
- **Port-forward**: `kubectl -n monitoring port-forward svc/victoria-metrics 8428:8428`
- **Internal URL**: `http://victoria-metrics.monitoring.svc.cluster.local:8428`

## Prometheus Compatibility

Victoria Metrics is fully compatible with:
- **PromQL**: Same query language
- **Scrape configs**: Uses same `prometheus.yml` format
- **API endpoints**: `/api/v1/query`, `/api/v1/query_range`, etc.
- **Grafana**: Works as a Prometheus datasource (use port 8428)

## Grafana Configuration

Configure Grafana to use Victoria Metrics as a Prometheus datasource:
- **URL**: `http://victoria-metrics.monitoring.svc.cluster.local:8428`
- **Type**: Prometheus

All existing Prometheus dashboards will work without modification.

## Migrating from Prometheus

1. Deploy Victoria Metrics alongside Prometheus
2. Update Grafana datasource URL
3. Verify dashboards work correctly
4. Remove Prometheus deployment

## Dependencies

None
