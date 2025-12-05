# Install Kubernetes Dashboard Role

This Ansible role installs the Kubernetes Dashboard on a Kubernetes cluster.

## Features

- Downloads and deploys the official Kubernetes Dashboard manifest
- Creates an admin user with cluster-admin privileges
- Configures service exposure (NodePort or LoadBalancer)
- Provides admin token for dashboard access

## Variables

### Dashboard Configuration
- `k8s_dashboard_version`: Version of Kubernetes Dashboard to install (default: "v2.7.0")
- `k8s_dashboard_namespace`: Namespace for dashboard deployment (default: "kubernetes-dashboard")
- `k8s_dashboard_service_type`: Service type for dashboard access - "NodePort" or "LoadBalancer" (default: "NodePort")
- `k8s_dashboard_node_port`: Port number for NodePort service (default: 30443)

### Manifest URLs and Paths
- `k8s_dashboard_manifest_url`: URL to download dashboard manifest
- `k8s_dashboard_manifest_dest`: Local path for downloaded manifest

## Usage

Include this role in your playbook:

```yaml
- hosts: kubernetes-master
  roles:
    - install_k8s_dashboard
```

## Access

After successful installation, the role will display:
- Dashboard access URL
- Admin token for authentication