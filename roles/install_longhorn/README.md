# install_longhorn

Deploys Longhorn distributed block storage system for Kubernetes.

## Requirements

- Kubernetes cluster with kubectl configured
- open-iscsi installed on all nodes

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `longhorn_namespace` | `longhorn-system` | Kubernetes namespace |
| `longhorn_version` | `v1.10.1` | Longhorn version |
| `longhorn_iscsi_nodes` | `[]` | List of nodes to install open-iscsi on |

## Usage

```yaml
- hosts: localhost
  roles:
    - install_longhorn
  vars:
    longhorn_iscsi_nodes:
      - node1
      - node2
      - node3
```

## Access

- **UI**: `kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80`
- Then visit: http://localhost:8080

## Features

- Distributed block storage
- Automatic volume replication
- Snapshot and backup support
- Volume expansion
- Storage class provisioner

## Dependencies

None
