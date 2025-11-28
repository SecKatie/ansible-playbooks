# install_homepage

Deploys Homepage dashboard - a modern, customizable homepage for your server.

## Requirements

- Kubernetes cluster with kubectl configured
- Traefik ingress controller

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `homepage_namespace` | `homepage` | Kubernetes namespace |
| `homepage_image` | `ghcr.io/gethomepage/homepage:latest` | Homepage container image |
| `homepage_cpu_request` | `10m` | CPU request |
| `homepage_cpu_limit` | `200m` | CPU limit |
| `homepage_memory_request` | `50Mi` | Memory request |
| `homepage_memory_limit` | `128Mi` | Memory limit |
| `homepage_ingress_enabled` | `true` | Enable Traefik IngressRoute |
| `homepage_ingress_host` | `homepage.corp.mulliken.net` | Ingress hostname |

## Configuration

The dashboard is configured via the ConfigMap in `templates/configmap.yaml.j2`. Key sections:

- **settings.yaml**: Theme, layout, title
- **services.yaml**: Service bookmarks and widgets
- **widgets.yaml**: Dashboard widgets (datetime, etc.)
- **kubernetes.yaml**: Kubernetes integration settings

### Kubernetes Integration

Homepage can show Kubernetes metrics for services. To enable:

1. RBAC is automatically configured for cluster access
2. Add `namespace` and `app` fields to services in the ConfigMap:

```yaml
- Jellyfin:
    icon: jellyfin.png
    href: https://jellyfin.corp.mulliken.net
    description: Media server
    namespace: jellyfin
    app: jellyfin
```

## Usage

```yaml
- hosts: localhost
  roles:
    - install_homepage
```

## Customization

To customize the dashboard after deployment:

```bash
# Edit ConfigMap
kubectl edit configmap homepage-config -n homepage

# Restart to apply changes
kubectl rollout restart deployment/homepage -n homepage
```

## Access

- **Ingress**: https://homepage.corp.mulliken.net
- **Port-forward**: `kubectl -n homepage port-forward svc/homepage 3000:3000`

## Dependencies

None
