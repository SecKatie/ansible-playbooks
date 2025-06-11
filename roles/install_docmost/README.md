# Install Docmost Role

This Ansible role installs Docmost documentation platform on a Kubernetes cluster.

## Features

- Deploys Docmost application with PostgreSQL database and Redis
- Includes CloudFlared tunnel configuration
- Sets up persistent storage for application data
- Configures sealed secrets for sensitive data

## Components Deployed

- Docmost application deployment
- PostgreSQL database
- Redis for caching
- CloudFlared tunnel for external access
- Kubernetes Services for networking
- Sealed Secrets for database credentials
- ConfigMaps for application configuration
- Persistent storage volumes

## Files Structure

The role deploys the following Kubernetes resources from the `files/docmost/` directory:

- `namespace.yaml` - Docmost namespace
- `docmost.yaml` - Main application deployment
- `postgres.yaml` - PostgreSQL database
- `redis.yaml` - Redis cache
- `cloudflared.yaml` - CloudFlared tunnel
- `sealedsecrets.yaml` - Encrypted credentials
- `configmap.yaml` - Application configuration
- `storage.yaml` - Persistent volume claims
- `secrets.example.yaml` - Example secrets file

## Usage

Include this role in your playbook:

```yaml
- hosts: kubernetes-master
  roles:
    - install_docmost
```

## Prerequisites

- Kubernetes cluster with sealed-secrets controller installed
- Sufficient storage for persistent volumes
- Storage class configured for dynamic provisioning