# install_headlamp

Deploys Headlamp, a modern open-source Kubernetes web UI with no commercial upselling.

## Overview

Headlamp is a fully-featured, user-friendly, and extensible Kubernetes web UI developed by the Kubernetes SIG. Unlike Portainer, it has no commercial edition and provides a clean interface for cluster management without upgrade pressure.

**Key Features:**
- Modern, responsive UI
- RBAC-aware (adapts to user permissions)
- Pod logs and shell access
- Resource management (deployments, pods, services, etc.)
- Helm chart support
- CRD support
- Plugin system for extensibility
- Multi-cluster support
- No commercial edition or upselling

## Requirements

- Kubernetes cluster with kubectl configured
- Helm 3.x installed
- Traefik with Gateway API enabled (see `configure_traefik_acme` role)
- Shared Gateway deployed (see `install_gateway` role)
- cert-manager with a ClusterIssuer configured

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `headlamp_namespace` | `headlamp` | Kubernetes namespace |
| `headlamp_helm_chart_version` | `0.38.0` | Headlamp Helm chart version |
| `headlamp_replica_count` | `1` | Number of replicas |
| `headlamp_service_type` | `ClusterIP` | Service type (ClusterIP, NodePort, LoadBalancer) |
| `headlamp_service_port` | `80` | Service port |
| `headlamp_cpu_request` | `100m` | CPU request |
| `headlamp_cpu_limit` | `500m` | CPU limit |
| `headlamp_memory_request` | `128Mi` | Memory request |
| `headlamp_memory_limit` | `256Mi` | Memory limit |
| `headlamp_ingress_enabled` | `true` | Enable HTTPRoute |
| `headlamp_ingress_host` | `headlamp.corp.mulliken.net` | Ingress hostname |
| `headlamp_gateway_name` | `traefik-gateway` | Gateway to attach HTTPRoute to |
| `headlamp_gateway_namespace` | `kube-system` | Namespace of the Gateway |
| `headlamp_in_cluster` | `true` | Run in-cluster mode |
| `headlamp_base_url` | `""` | Base URL path (if behind reverse proxy) |

## OIDC Configuration (Optional)

Headlamp supports OIDC for authentication:

| Variable | Default | Description |
|----------|---------|-------------|
| `headlamp_oidc_enabled` | `false` | Enable OIDC authentication |
| `headlamp_oidc_client_id` | `""` | OIDC client ID |
| `headlamp_oidc_client_secret` | `""` | OIDC client secret |
| `headlamp_oidc_issuer_url` | `""` | OIDC issuer URL |
| `headlamp_oidc_scopes` | `""` | OIDC scopes |

## Setup

No additional setup is required. The role will:

1. Add the Headlamp Helm repository
2. Create the headlamp namespace (via Helm)
3. Deploy Headlamp using Helm
4. Create an HTTPRoute attached to the shared Gateway
5. Wait for pods to be ready

## Usage

```yaml
- hosts: localhost
  roles:
    - install_headlamp
```

Or with tags in your main playbook:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags headlamp
```

## Access Methods

### Via Ingress (Recommended)
```
https://headlamp.corp.mulliken.net
```

### Via Port-Forward
```bash
kubectl -n headlamp port-forward svc/headlamp 8080:80
# Access at: http://localhost:8080
```

## Authentication

Headlamp uses token-based authentication by default:

1. Access Headlamp at your configured URL
2. Click "Sign In"
3. Headlamp will use your cluster's RBAC to determine permissions
4. You can authenticate with:
   - Service account tokens
   - OIDC (if configured)
   - Kubeconfig tokens

### Creating a Service Account Token

To create a service account with admin access:

```bash
# Create service account
kubectl create serviceaccount headlamp-admin -n headlamp

# Create cluster role binding
kubectl create clusterrolebinding headlamp-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=headlamp:headlamp-admin

# Create token secret
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: headlamp-admin-token
  namespace: headlamp
  annotations:
    kubernetes.io/service-account.name: headlamp-admin
type: kubernetes.io/service-account-token
EOF

# Get the token
kubectl get secret headlamp-admin-token -n headlamp -o jsonpath='{.data.token}' | base64 -d
```

Use this token to log in to Headlamp.

## Features

### Resource Management
- View and manage all Kubernetes resources
- Create, edit, and delete resources via UI or YAML
- Filter and search across resources
- Real-time updates

### Workload Management
- Manage Deployments, StatefulSets, DaemonSets
- Scale workloads
- View and manage Jobs and CronJobs
- Pod logs with filtering and download
- Shell access to containers

### Networking
- Manage Services, Ingresses, NetworkPolicies
- View service endpoints
- Port forwarding

### Configuration
- Manage ConfigMaps and Secrets
- Edit in YAML or form view
- Secret data encoding/decoding

### Storage
- View PersistentVolumes and PersistentVolumeClaims
- StorageClass management
- Volume usage statistics

### RBAC
- Manage Roles, ClusterRoles, RoleBindings
- ServiceAccount management
- Permission visualization

### Helm
- Browse installed Helm releases
- View release history
- Upgrade and rollback releases

### Monitoring
- Resource usage metrics (requires metrics-server)
- Node and pod statistics
- Event viewer with filtering

### Extensibility
- Plugin system for custom functionality
- Theming support
- Custom resource definitions (CRDs)

## Comparison with Portainer

| Feature | Headlamp | Portainer CE |
|---------|----------|--------------|
| Open Source | ✅ | ✅ |
| Commercial Edition | ❌ No | ✅ Yes (frequent upsells) |
| Kubernetes Native | ✅ | ✅ |
| Modern UI | ✅ | ✅ |
| Plugin System | ✅ | ❌ |
| Multi-cluster | ✅ | ✅ (BE only) |
| RBAC-aware | ✅ | ✅ |
| Active Development | ✅ Kubernetes SIG | ✅ |
| Resource Usage | Light | Medium |

## Troubleshooting

### Pods not starting

Check pod status:
```bash
kubectl get pods -n headlamp
kubectl describe pod -n headlamp <pod-name>
```

### HTTPRoute not working

Verify the HTTPRoute and Gateway:
```bash
kubectl get httproute -n headlamp
kubectl describe httproute headlamp -n headlamp
kubectl get gateway -n kube-system
```

Check Traefik logs:
```bash
kubectl logs -n kube-system deployment/traefik
```

### Authentication issues

Ensure your token is valid:
```bash
kubectl get secret headlamp-admin-token -n headlamp
```

Check service account permissions:
```bash
kubectl auth can-i --list --as=system:serviceaccount:headlamp:headlamp-admin
```

### Metrics not showing

Ensure metrics-server is installed:
```bash
kubectl get deployment metrics-server -n kube-system
```

## Upgrading

The role will automatically upgrade Headlamp if a newer chart version is specified:

1. Update `headlamp_helm_chart_version` in `defaults/main.yml`
2. Re-run the playbook

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags headlamp
```

## Uninstallation

```bash
helm uninstall headlamp -n headlamp
kubectl delete namespace headlamp
```

## Common Tasks

### Viewing Headlamp version
```bash
kubectl get deployment -n headlamp headlamp -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Checking Headlamp logs
```bash
kubectl logs -n headlamp deployment/headlamp -f
```

### Restarting Headlamp
```bash
kubectl rollout restart -n headlamp deployment/headlamp
```

### Enabling OIDC

Edit your playbook or inventory to include:

```yaml
headlamp_oidc_enabled: true
headlamp_oidc_client_id: "your-client-id"
headlamp_oidc_client_secret: "your-client-secret"
headlamp_oidc_issuer_url: "https://your-oidc-provider.com"
headlamp_oidc_scopes: "openid profile email"
```

Then redeploy:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags headlamp
```

## References

- [Headlamp Official Documentation](https://headlamp.dev/docs/)
- [Headlamp GitHub Repository](https://github.com/kubernetes-sigs/headlamp)
- [Helm Chart Repository](https://github.com/kubernetes-sigs/headlamp/tree/main/charts/headlamp)
- [Plugin Development Guide](https://headlamp.dev/docs/latest/development/plugins/)
- [OIDC Configuration Guide](https://headlamp.dev/docs/latest/installation/in-cluster/#oidc-authentication)