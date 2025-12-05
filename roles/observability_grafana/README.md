# install_grafana

Deploys Grafana dashboard for observability and visualization.

## Requirements

- Kubernetes cluster with kubectl configured
- Longhorn storage class (or modify `grafana_storage_class`)
- Sealed secrets controller deployed
- Prometheus deployed (for default datasource)

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `grafana_namespace` | `monitoring` | Kubernetes namespace |
| `grafana_image` | `grafana/grafana:11.4.0` | Grafana container image |
| `grafana_cpu_request` | `100m` | CPU request |
| `grafana_cpu_limit` | `500m` | CPU limit |
| `grafana_memory_request` | `128Mi` | Memory request |
| `grafana_memory_limit` | `256Mi` | Memory limit |
| `grafana_storage_size` | `10Gi` | PVC storage size |
| `grafana_storage_class` | `longhorn` | Storage class |
| `grafana_ingress_enabled` | `true` | Enable Traefik IngressRoute |
| `grafana_ingress_host` | `grafana.corp.mulliken.net` | Ingress hostname |
| `grafana_prometheus_url` | `http://prometheus.monitoring.svc.cluster.local:9090` | Prometheus datasource URL |

## Setup

Before deploying, create the admin credentials sealed secret:

```bash
# 1. Create raw secret
cat > /tmp/grafana-secrets.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin-credentials
  namespace: monitoring
type: Opaque
stringData:
  admin-user: admin
  admin-password: your-secure-password-here
EOF

# 2. Seal the secret
kubeseal --format=yaml < /tmp/grafana-secrets.yaml > roles/install_grafana/files/sealedsecrets.yaml

# 3. Clean up
rm /tmp/grafana-secrets.yaml
```

## Usage

```yaml
- hosts: localhost
  roles:
    - install_grafana
```

## Access

- **Ingress**: https://grafana.corp.mulliken.net
- **Port-forward**: `kubectl -n monitoring port-forward svc/grafana 3000:3000`

## Dependencies

- `install_prometheus` (for datasource)
