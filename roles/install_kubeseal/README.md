# Install Kubeseal Role

This Ansible role installs Kubeseal (Sealed Secrets) on a Kubernetes cluster. Kubeseal allows you to encrypt your Secret resources at rest, so that they can be stored safely in Git repositories.

## Features

- Downloads and deploys the official Kubeseal controller manifest
- Installs the sealed-secrets operator in the kube-system namespace
- Enables GitOps-friendly secret management

## Variables

- `k8s_kubeseal_version`: Version of Kubeseal to install (default: "0.28.0")
- `k8s_kubeseal_manifest_url`: URL to download kubeseal manifest
- `k8s_kubeseal_manifest_dest`: Local path for downloaded manifest

## Usage

Include this role in your playbook:

```yaml
- hosts: kubernetes-master
  roles:
    - install_kubeseal
```

## About Sealed Secrets

Sealed Secrets are encrypted Secret resources that can only be decrypted by the controller running in the cluster. This allows you to store encrypted secrets in Git repositories and manage them through GitOps workflows.