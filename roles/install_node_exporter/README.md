# install_node_exporter

Deploys Node Exporter as a DaemonSet for hardware and OS metrics from all cluster nodes.

## Requirements

- Kubernetes cluster with kubectl configured

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `node_exporter_namespace` | `monitoring` | Kubernetes namespace |
| `node_exporter_image` | `prom/node-exporter:v1.8.2` | Node Exporter container image |
| `node_exporter_cpu_request` | `100m` | CPU request |
| `node_exporter_cpu_limit` | `200m` | CPU limit |
| `node_exporter_memory_request` | `128Mi` | Memory request |
| `node_exporter_memory_limit` | `256Mi` | Memory limit |

## Usage

```yaml
- hosts: localhost
  roles:
    - install_node_exporter
```

## Metrics Exposed

Node Exporter provides metrics for:

- CPU usage and load
- Memory usage
- Disk I/O and space
- Network statistics
- System load
- And many more hardware/OS metrics

## Access

- **Internal**: http://node-exporter.monitoring.svc.cluster.local:9100/metrics
- Prometheus automatically discovers and scrapes all Node Exporter instances

## Dependencies

- `install_prometheus` (to scrape the metrics)
