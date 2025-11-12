# Ansible Playbooks - Usage Guide

This repository contains Ansible playbooks and roles for deploying and managing infrastructure, including Raspberry Pi nodes and Kubernetes applications.

## Prerequisites

- Ansible installed on your local machine
- kubectl configured with access to your Kubernetes cluster
- SSH access to target hosts (for Raspberry Pi nodes)
- Inventory file configured at `inventory/hosts.yml`

## Available Playbooks

### 1. Infrastructure Deploy Complete
**File**: `playbooks/infrastructure-deploy-complete.yml`

Deploys the complete infrastructure including Raspberry Pi setup and Kubernetes applications.

**What it does**:
- Configures Raspberry Pi nodes (iSCSI, cgroups)
- Deploys Kubeseal for sealed secrets
- Installs cert-manager for TLS certificate management
- Deploys Kubernetes Dashboard
- Installs Ghost blogging platform
- Installs Docmost documentation platform
- Installs Jellyfin media server
- Installs Sonarr PVR with Mullvad VPN protection

**Usage**:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure-deploy-complete.yml
```

### 2. Install Kubernetes Apps
**File**: `playbooks/install_k8s_apps.yml`

Installs Kubernetes applications on localhost (without Raspberry Pi setup).

**What it does**:
- Deploys Kubeseal
- Installs cert-manager
- Deploys Kubernetes Dashboard

**Usage**:
```bash
ansible-playbook playbooks/install_k8s_apps.yml
```

### 3. Maintenance - Update Packages
**File**: `playbooks/maintenance-update-packages.yml`

Updates packages on target hosts.

**Usage**:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/maintenance-update-packages.yml
```

## Available Roles

### Infrastructure Roles

- **rpi_setup**: Configures Raspberry Pi nodes with iSCSI and cgroup settings
- **install_kubeseal**: Deploys Sealed Secrets controller
- **install_cert_manager**: Installs cert-manager for certificate management
- **install_k8s_dashboard**: Deploys Kubernetes Dashboard with Helm

### Application Roles

- **install_ghost**: Deploys Ghost blogging platform with MySQL backend
- **install_docmost**: Deploys Docmost documentation platform with PostgreSQL and Redis
- **install_jellyfin**: Deploys Jellyfin media server with Cloudflare tunnel support
- **install_sonarr**: Deploys Sonarr PVR for TV shows with Mullvad VPN via gluetun sidecar

## Common Issues and Solutions

### Issue: Helm repository not cached

**Error**: `Error: no cached repo found. (try 'helm repo update')`

**Solution**: The `install_k8s_dashboard` role now includes a helm repo update step. If you encounter this, ensure you're using the latest version of the role.

### Issue: PersistentVolumeClaim storage size mismatch

**Error**: `spec.resources.requests.storage: Forbidden: field can not be less than status.capacity`

**Solution**: This occurs when trying to reduce PVC size. Update the storage.yaml file to match or exceed the current PVC size. You cannot reduce PVC sizes in Kubernetes.

### Issue: Ghost/Docmost roles skipped

**Error**: `Unable to find 'ghost' in expected paths`

**Solution**: The roles now use `{{ role_path }}/files/*.yaml` pattern for fileglob. Ensure your role uses the correct path.

### Issue: Cloudflared not found (Jellyfin)

**Error**: `/bin/sh: cloudflared: command not found`

**Solution**: This is expected if cloudflared is not installed locally. The playbook will show manual setup instructions for creating the Cloudflare tunnel.

## Kubernetes Dashboard Access

After deploying the Kubernetes Dashboard:

1. Start port-forwarding:
   ```bash
   kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
   ```

2. Access the dashboard at: https://localhost:8443

3. Use the admin token displayed in the playbook output to log in

## Working with Sealed Secrets

### What are Sealed Secrets?

Sealed Secrets allow you to encrypt Kubernetes secrets so they can be safely stored in Git repositories. The sealed-secrets controller running in your cluster is the only thing that can decrypt them.

### Installing kubeseal CLI

The kubeseal CLI tool is required to create sealed secrets:

```bash
# macOS
brew install kubeseal

# Linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.33.1/kubeseal-0.33.1-linux-amd64.tar.gz
tar -xvzf kubeseal-0.33.1-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

### Creating Sealed Secrets

1. **Create a raw secret YAML file** (never commit this to Git):
   ```bash
   cat > /tmp/my-secret.yaml <<EOF
   apiVersion: v1
   kind: Secret
   metadata:
     name: my-secret
     namespace: my-namespace
   type: Opaque
   stringData:
     username: "myuser"
     password: "mypassword"
   EOF
   ```

2. **Seal the secret**:
   ```bash
   kubeseal --format=yaml < /tmp/my-secret.yaml > my-sealed-secret.yaml
   ```

3. **Update the Ansible role** with the sealed secret:
   - Copy the contents of `my-sealed-secret.yaml`
   - Update the corresponding file in `roles/<role-name>/files/sealedsecrets.yaml`

4. **Apply and verify**:
   ```bash
   # The sealed secret will be automatically unsealed by the controller
   kubectl apply -f roles/<role-name>/files/sealedsecrets.yaml

   # Verify the secret was created
   kubectl get secret my-secret -n my-namespace
   ```

### Important Notes about Sealed Secrets

- **The sealed-secrets controller must be running** in your cluster before you can unseal secrets
- **Sealed secrets are cluster-specific** - they can only be decrypted by the cluster that has the matching private key
- **Backup the controller's private key** if you need to restore the cluster:
  ```bash
  kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key.yaml
  ```
- **Never commit raw secrets to Git** - only commit the sealed versions
- **Updating secrets**: If you need to change a secret value, create a new sealed secret and apply it. The controller will update the underlying secret.

### Example: Updating Docmost Secrets

1. Generate new passwords:
   ```bash
   POSTGRES_PASSWORD=$(openssl rand -hex 16)
   APP_SECRET=$(openssl rand -hex 32)
   ```

2. Create raw secret:
   ```bash
   cat > /tmp/docmost-secrets.yaml <<EOF
   apiVersion: v1
   kind: Secret
   metadata:
     name: docmost-secrets
     namespace: docmost
   type: Opaque
   stringData:
     APP_SECRET: "$APP_SECRET"
     POSTGRES_PASSWORD: "$POSTGRES_PASSWORD"
     DATABASE_URL: "postgresql://docmost:$POSTGRES_PASSWORD@postgres:5432/docmost?schema=public"
   EOF
   ```

3. Seal and update:
   ```bash
   kubeseal --format=yaml < /tmp/docmost-secrets.yaml > /tmp/docmost-sealed.yaml
   # Copy contents to roles/install_docmost/files/sealedsecrets.yaml
   ```

4. If updating an existing database password, you must also update the database:
   ```bash
   kubectl exec -n docmost postgres-0 -- psql -U docmost -c "ALTER USER docmost WITH PASSWORD 'new-password';"
   ```

## Sonarr with Mullvad VPN

The Sonarr role deploys a PVR (Personal Video Recorder) for automatically managing and downloading TV shows. All traffic is routed through Mullvad VPN using a gluetun sidecar container.

### Initial Setup

1. **Get Mullvad WireGuard credentials**:
   - Log in to https://mullvad.net/account
   - Navigate to "WireGuard configuration"
   - Generate a new WireGuard key if needed
   - Note your private key and IP addresses

2. **Create the sealed secret**:
   ```bash
   # Create raw secret (replace with your actual values)
   cat > /tmp/sonarr-vpn-secrets.yaml <<EOF
   apiVersion: v1
   kind: Secret
   metadata:
     name: sonarr-vpn-secrets
     namespace: sonarr
   type: Opaque
   stringData:
     WIREGUARD_PRIVATE_KEY: "your_private_key_here"
     WIREGUARD_ADDRESSES: "10.x.x.x/32,fc00:bbbb:bbbb:bb01::x:xxxx/128"
     SERVER_CITIES: "Atlanta GA"
   EOF

   # Seal it
   kubeseal --format=yaml < /tmp/sonarr-vpn-secrets.yaml > roles/install_sonarr/files/sealedsecrets.yaml

   # Clean up
   rm /tmp/sonarr-vpn-secrets.yaml
   ```

3. **Deploy Sonarr**:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/infrastructure-deploy-complete.yml
   ```

### Accessing Sonarr

```bash
# Port forward to access Sonarr
kubectl -n sonarr port-forward svc/sonarr 8989:8989

# Access at: http://localhost:8989
```

### Verifying VPN Connection

```bash
# Check VPN public IP
kubectl exec -n sonarr deployment/sonarr -c gluetun -- wget -qO- http://localhost:8000/v1/publicip/ip

# Check VPN logs
kubectl logs -n sonarr deployment/sonarr -c gluetun

# Check Sonarr logs
kubectl logs -n sonarr deployment/sonarr -c sonarr
```

### Configuring Sonarr for Jellyfin Integration

Sonarr shares the same NFS media storage as Jellyfin. Configure these paths in Sonarr:

- **Root Folder for TV Shows**: `/media/tv`
- **Download Client Path**: `/media/downloads`

Recommended directory structure on NFS (`/volume2/media`):
```
/volume2/media/
├── tv/              # Sonarr organizes TV shows here
│   ├── Show Name/
│   └── Another Show/
├── downloads/       # Download client output
│   ├── complete/
│   └── incomplete/
└── movies/          # For future use (Radarr, etc.)
```

Jellyfin will automatically see new TV shows added to `/media/tv`.

### Updating Mullvad Credentials

If you need to rotate your Mullvad VPN credentials:

1. Generate new credentials from mullvad.net
2. Create and seal new secret (see Initial Setup above)
3. Re-run the playbook or apply directly:
   ```bash
   kubectl apply -f roles/install_sonarr/files/sealedsecrets.yaml
   kubectl rollout restart -n sonarr deployment/sonarr
   ```

## Notes

- The deprecated `k8s` role has been split into individual application-specific roles
- Always use the inventory file with `-i inventory/hosts.yml` for playbooks that target remote hosts
- Roles are idempotent and safe to run multiple times
- Check the PLAY RECAP at the end of each run to verify success

## Getting Help

If you encounter issues not covered here, check:
- Ansible output for specific error messages
- Kubernetes pod logs: `kubectl logs -n <namespace> <pod-name>`
- Role documentation in `roles/<role-name>/README.md` (if available)
