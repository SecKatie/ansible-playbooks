# Install Ghost Role

This Ansible role installs Ghost blogging platform on a Kubernetes cluster.

## Features

- Deploys Ghost application with MySQL database
- Includes CloudFlared tunnel configuration
- Sets up persistent storage for Ghost data
- Configures sealed secrets for sensitive data

## Components Deployed

- Ghost StatefulSet
- MySQL database StatefulSet  
- CloudFlared tunnel for external access
- Kubernetes Services for networking
- Sealed Secrets for database credentials
- Persistent storage configuration

## Files Structure

The role deploys the following Kubernetes resources from the `files/ghost/` directory:

- `namespace.yaml` - Ghost namespace
- `statefulset.yaml` - Ghost application
- `mysql-statefulset.yaml` - MySQL database
- `mysql-service.yaml` - MySQL service
- `service.yaml` - Ghost service
- `cloudflared.yaml` - CloudFlared tunnel
- `mysql-sealedsecret.yaml` - Encrypted database credentials

## Usage

Include this role in your playbook:

```yaml
- hosts: kubernetes-master
  roles:
    - install_ghost
```

## Prerequisites

- Kubernetes cluster with sealed-secrets controller installed
- Sufficient storage for persistent volumes