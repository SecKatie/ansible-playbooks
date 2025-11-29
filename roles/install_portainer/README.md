# install_portainer

Deploys Portainer CE (Community Edition) for visual Kubernetes cluster management.

## Overview

Portainer is a lightweight management UI that allows you to easily manage your Kubernetes clusters, containers, images, volumes, and more through a web interface. This role deploys Portainer using the official Helm chart.

## Requirements

- Kubernetes cluster with kubectl configured
- Helm 3.x installed
- Longhorn storage class (or modify `portainer_storage_class`)
- Traefik ingress controller for external access

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `portainer_namespace` | `portainer` | Kubernetes namespace |
| `portainer_helm_chart_version` | `2.33.5` | Portainer Helm chart version |
| `portainer_service_type` | `ClusterIP` | Service type (ClusterIP, NodePort, LoadBalancer) |
| `portainer_service_port` | `9443` | HTTPS service port |
| `portainer_service_http_port` | `9000` | HTTP service port |
| `portainer_cpu_request` | `100m` | CPU request |
| `portainer_cpu_limit` | `500m` | CPU limit |
| `portainer_memory_request` | `256Mi` | Memory request |
| `portainer_memory_limit` | `512Mi` | Memory limit |
| `portainer_storage_size` | `10Gi` | PVC storage size |
| `portainer_storage_class` | `longhorn` | Storage class |
| `portainer_ingress_enabled` | `true` | Enable Traefik IngressRoute |
| `portainer_ingress_host` | `portainer.corp.mulliken.net` | Ingress hostname |
| `portainer_tls_cert_resolver` | `cloudflare` | Traefik cert resolver |
| `portainer_tls_domain` | `corp.mulliken.net` | TLS domain |
| `portainer_enable_tls` | `true` | Force HTTPS |
| `portainer_enable_edge_compute` | `false` | Enable Edge compute features |

## Setup

No additional setup is required. The role will:

1. Add the Portainer Helm repository
2. Create the portainer namespace (via Helm)
3. Deploy Portainer using Helm
4. Create a Traefik IngressRoute for external access
5. Wait for pods to be ready

## Usage

```yaml
- hosts: localhost
  roles:
    - install_portainer
```

Or with tags in your main playbook:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags portainer
```

## First-Time Setup

On first access, you'll need to create an admin user:

1. Access Portainer at https://portainer.corp.mulliken.net
2. Create an admin username and password (minimum 12 characters)
3. Portainer will automatically connect to your local Kubernetes cluster
4. Start managing your cluster through the UI

## Access Methods

### Via Ingress (Recommended)
```
https://portainer.corp.mulliken.net
```

### Via Port-Forward
```bash
kubectl -n portainer port-forward svc/portainer 9443:9443
# Access at: https://localhost:9443
```

### Via HTTP (if needed)
```bash
kubectl -n portainer port-forward svc/portainer 9000:9000
# Access at: http://localhost:9000
```

## Features

- **Visual Kubernetes Management**: Manage deployments, pods, services, and more through a UI
- **Resource Monitoring**: View CPU, memory, and storage usage
- **Log Viewing**: Access container logs without kubectl
- **Shell Access**: Execute commands in containers via web terminal
- **Helm Chart Deployment**: Deploy applications from Helm repositories
- **GitOps Integration**: Deploy applications from Git repositories
- **RBAC Management**: Manage Kubernetes roles and permissions
- **Multi-Cluster**: Connect and manage multiple Kubernetes clusters (add additional clusters after initial setup)

## Security Notes

- Admin credentials are set on first login (not stored in secrets)
- Portainer uses a ClusterRole with cluster-admin permissions
- HTTPS is enforced by default
- Access is controlled through Traefik ingress with Cloudflare SSL

## Troubleshooting

### Pods not starting
Check storage class exists:
```bash
kubectl get sc
```

Verify pod status:
```bash
kubectl get pods -n portainer
kubectl describe pod -n portainer <pod-name>
```

### Can't access via ingress
Verify IngressRoute was created:
```bash
kubectl get ingressroute -n portainer
kubectl describe ingressroute portainer -n portainer
```

Check Traefik logs:
```bash
kubectl logs -n traefik deployment/traefik
```

### Forgot admin password
Reset by deleting the Portainer data volume and redeploying:
```bash
kubectl delete pvc -n portainer portainer
kubectl rollout restart -n portainer deployment/portainer
```

**Warning**: This will delete all Portainer configuration including connected environments and user settings.

## Upgrading

The role will automatically upgrade Portainer if a newer chart version is specified:

1. Update `portainer_helm_chart_version` in `defaults/main.yml`
2. Re-run the playbook
3. Clear your browser cache if you experience UI issues

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags portainer
```

## Uninstallation

```bash
helm uninstall portainer -n portainer
kubectl delete namespace portainer
```

## Common Tasks

### Viewing Portainer version
```bash
kubectl get deployment -n portainer portainer -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Checking Portainer logs
```bash
kubectl logs -n portainer deployment/portainer -f
```

### Restarting Portainer
```bash
kubectl rollout restart -n portainer deployment/portainer
```

## References

- [Portainer Documentation](https://docs.portainer.io/)
- [Portainer Kubernetes Deployment](https://docs.portainer.io/start/install-ce/server/kubernetes)
- [Portainer Helm Chart Repository](https://github.com/portainer/k8s)
- [Portainer Release Notes](https://www.portainer.io/blog)