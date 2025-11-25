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
- Installs observability stack (Prometheus, Node Exporter, Grafana)
- Deploys Kubernetes Dashboard
- Installs Jellyfin media server
- Installs Media stack (Sonarr, Radarr, qBittorrent) with Mullvad VPN protection

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
- **install_prometheus**: Deploys Prometheus metrics server for monitoring
- **install_node_exporter**: Deploys Node Exporter DaemonSet for system metrics
- **install_grafana**: Deploys Grafana dashboard for observability and visualization
- **install_k8s_dashboard**: Deploys Kubernetes Dashboard with Helm

### Application Roles

- **install_jellyfin**: Deploys Jellyfin media server with Cloudflare tunnel support
- **install_media**: Deploys media stack (Sonarr, Radarr, qBittorrent, Jackett) with Mullvad VPN via gluetun sidecar

## Common Issues and Solutions

### Issue: Helm repository not cached

**Error**: `Error: no cached repo found. (try 'helm repo update')`

**Solution**: The `install_k8s_dashboard` role now includes a helm repo update step. If you encounter this, ensure you're using the latest version of the role.

### Issue: PersistentVolumeClaim storage size mismatch

**Error**: `spec.resources.requests.storage: Forbidden: field can not be less than status.capacity`

**Solution**: This occurs when trying to reduce PVC size. Update the storage.yaml file to match or exceed the current PVC size. You cannot reduce PVC sizes in Kubernetes.

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

## Observability Stack (Grafana + Prometheus + Node Exporter)

The observability stack provides comprehensive monitoring and visualization for your Kubernetes cluster and applications.

### Architecture

- **Prometheus**: Metrics collection and storage server that scrapes metrics from configured targets
- **Node Exporter**: DaemonSet that exposes hardware and OS metrics from every cluster node
- **Grafana**: Visualization dashboard with Prometheus pre-configured as the default data source

### Initial Setup

Before deploying Grafana, you must create sealed secrets for the admin credentials:

1. **Create the admin credentials secret**:
   ```bash
   # Create raw secret with your desired credentials
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
   ```

2. **Seal the secret**:
   ```bash
   kubeseal --format=yaml < /tmp/grafana-secrets.yaml > roles/install_grafana/files/sealedsecrets.yaml
   ```

3. **Clean up the temporary file**:
   ```bash
   rm /tmp/grafana-secrets.yaml
   ```

4. **Deploy the stack**:
   ```bash
   # Deploy only the observability stack
   ansible-playbook -i inventory/hosts.yml playbooks/infrastructure-deploy-complete.yml --tags observability

   # Or deploy the full infrastructure (which includes observability)
   ansible-playbook -i inventory/hosts.yml playbooks/infrastructure-deploy-complete.yml
   ```

### Accessing the Dashboards

#### Grafana

```bash
# Port forward to access Grafana
kubectl -n monitoring port-forward svc/grafana 3000:3000

# Access at: http://localhost:3000
# Login with the credentials you configured in the sealed secret
```

#### Prometheus

```bash
# Port forward to access Prometheus
kubectl -n monitoring port-forward svc/prometheus 9090:9090

# Access at: http://localhost:9090
```

### What's Monitored

The default Prometheus configuration scrapes metrics from:

- **Prometheus itself**: Self-monitoring
- **Node Exporter**: System metrics (CPU, memory, disk, network) from all cluster nodes
- **Kubernetes API Server**: Cluster-level metrics
- **Kubernetes Nodes**: Node-level metrics with node labels
- **Kubernetes Pods**: Any pod annotated with `prometheus.io/scrape: "true"`

### Adding Custom Metrics to Your Applications

To expose metrics from your applications to Prometheus:

1. **Add annotations to your pod**:
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     annotations:
       prometheus.io/scrape: "true"
       prometheus.io/port: "8080"        # Your metrics port
       prometheus.io/path: "/metrics"    # Your metrics endpoint
   ```

2. **Expose metrics in your application**:
   - Implement a `/metrics` endpoint in your application
   - Use Prometheus client libraries for your language
   - Prometheus will automatically discover and scrape your pod

### Importing Dashboards to Grafana

Grafana has thousands of pre-built dashboards available at https://grafana.com/grafana/dashboards/

Popular dashboards for Kubernetes monitoring:

- **Node Exporter Full** (ID: 1860): Comprehensive system metrics
- **Kubernetes Cluster Monitoring** (ID: 7249): Cluster overview
- **Kubernetes Pod Monitoring** (ID: 6417): Pod-level metrics

To import a dashboard:

1. Log in to Grafana
2. Click **Dashboards** → **Import**
3. Enter the dashboard ID (e.g., 1860)
4. Select **Prometheus** as the data source
5. Click **Import**

### Configuring Data Retention

By default, Prometheus retains metrics for 30 days. To change this:

1. Edit `roles/install_prometheus/files/prometheus.yaml`
2. Update the `--storage.tsdb.retention.time` argument
3. Redeploy: `ansible-playbook -i inventory/hosts.yml playbooks/infrastructure-deploy-complete.yml --tags prometheus`

### Storage Requirements

- **Prometheus**: 20Gi by default (configurable in `roles/install_prometheus/files/storage.yaml`)
- **Grafana**: 10Gi by default (configurable in `roles/install_grafana/files/storage.yaml`)

Adjust these values based on your retention requirements and cluster size.

### Troubleshooting

#### Grafana won't start - sealed secret error

**Error**: Pod fails with secret mount errors

**Solution**: Ensure you created and sealed the admin credentials (see Initial Setup above)

#### Prometheus not scraping targets

Check Prometheus targets:
```bash
# Open Prometheus UI
kubectl -n monitoring port-forward svc/prometheus 9090:9090

# Visit http://localhost:9090/targets
# All targets should show as "UP"
```

#### No data in Grafana dashboards

1. Check that Prometheus is running: `kubectl get pods -n monitoring`
2. Verify Prometheus is scraping targets (see above)
3. In Grafana, go to **Configuration** → **Data Sources** → **Prometheus** and click **Test**
4. Check that the Prometheus URL is correct: `http://prometheus.monitoring.svc.cluster.local:9090`

### Updating Admin Credentials

To change Grafana admin credentials:

1. Create new sealed secret (see Initial Setup)
2. Apply the new secret: `kubectl apply -f roles/install_grafana/files/sealedsecrets.yaml`
3. Restart Grafana: `kubectl rollout restart -n monitoring deployment/grafana`

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

## Media Stack with Mullvad VPN

The media role deploys Sonarr (TV), Radarr (movies), qBittorrent (downloads), and Jackett (indexers). All traffic is routed through Mullvad VPN using a gluetun sidecar container.

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
     name: media-vpn-secrets
     namespace: media
   type: Opaque
   stringData:
     WIREGUARD_PRIVATE_KEY: "your_private_key_here"
     WIREGUARD_ADDRESSES: "10.x.x.x/32,fc00:bbbb:bbbb:bb01::x:xxxx/128"
     SERVER_CITIES: "Atlanta GA"
   EOF

   # Seal it
   kubeseal --format=yaml < /tmp/sonarr-vpn-secrets.yaml > roles/install_media/files/sealedsecrets.yaml

   # Clean up
   rm /tmp/sonarr-vpn-secrets.yaml
   ```

3. **Deploy the media stack**:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/infrastructure-deploy-complete.yml
   ```

### Accessing Sonarr

```bash
# Port forward to access Sonarr
kubectl -n media port-forward svc/sonarr 8989:8989

# Access at: http://localhost:8989
```

### Accessing qBittorrent

qBittorrent runs as a shared download client. To access the web UI:

```bash
# Port forward to access qBittorrent
kubectl -n media port-forward svc/qbittorrent 8080:8080

# Access at: http://localhost:8080
```

### Accessing Jackett

Jackett (indexer manager) provides indexer support. To access the web UI:

```bash
# Port forward to access Jackett
kubectl -n media port-forward svc/jackett 9117:9117

# Access at: http://localhost:9117
```

### Accessing Radarr

```bash
# Port forward to access Radarr
kubectl -n media port-forward svc/radarr 7878:7878

# Access at: http://localhost:7878
```

### Verifying VPN Connection

```bash
# Check VPN public IP (from any media pod)
kubectl exec -n media deployment/sonarr -c gluetun -- wget -qO- http://localhost:8000/v1/publicip/ip

# Check VPN logs
kubectl logs -n media deployment/sonarr -c gluetun
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
   kubectl apply -f roles/install_media/files/sealedsecrets.yaml
   kubectl rollout restart -n media deployment/sonarr
   kubectl rollout restart -n media deployment/radarr
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
