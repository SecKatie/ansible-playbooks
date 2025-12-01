# Ansible Playbooks - Usage Guide

This repository contains Ansible playbooks and roles for deploying and managing infrastructure, including Raspberry Pi nodes and Kubernetes applications.

## Prerequisites

- Ansible installed on your local machine
- kubectl configured with access to your Kubernetes cluster
- SSH access to target hosts (for Raspberry Pi nodes)
- Inventory file configured at `inventory/hosts.yml`

## Main Playbooks

### 1. Deploy - Complete Infrastructure Deployment
**File**: `playbooks/deploy.yml`

The primary playbook for deploying the entire infrastructure stack with granular control via tags. This playbook is modular and imports specialized playbooks for each component.

**Modular Structure**:
The deploy playbook imports the following sub-playbooks:
- `infrastructure.yml` - Raspberry Pi configuration, NFS support
- `k3s.yml` - K3s cluster agent configuration
- `core.yml` - Storage (Longhorn), Security (cert-manager), Networking (Traefik)
- `observability.yml` - Victoria Metrics, Grafana, Node Exporter
- `dashboards.yml` - Kubernetes Dashboard, Headlamp, Homepage
- `applications.yml` - Jellyfin, Media stack, Paperless, Plane, Immich

Each sub-playbook can also be run independently for targeted deployments.

**Usage**:
```bash
# Deploy everything
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml

# Deploy only infrastructure components
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags infrastructure

# Deploy only observability stack
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags observability

# Deploy specific application
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags jellyfin
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags media
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags paperless
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags immich

# Deploy multiple components
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags "infrastructure,core,applications"

# Run individual sub-playbooks
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml
ansible-playbook -i inventory/hosts.yml playbooks/core.yml
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml
```

**Available Tags**:
- `infrastructure` - Base infrastructure setup (Pi config, NFS)
- `k3s` - K3s cluster configuration
- `core` - All core Kubernetes components
- `storage` - Storage solutions (Longhorn)
- `security` - Security components (cert-manager)
- `networking` - Networking components (Traefik)
- `observability` - Monitoring stack (Victoria Metrics, Grafana, Node Exporter)
- `dashboards` - Dashboard applications (K8s Dashboard, Headlamp, Homepage)
- `applications` - All user-facing applications
- `jellyfin` - Jellyfin media server
- `media` - Media management stack (Sonarr, Radarr, qBittorrent, Jackett)
- `paperless` - Paperless-ngx document management
- `headlamp` - Headlamp Kubernetes web UI
- `plane` - Plane project management
- `immich` - Immich photo management

### 2. Update - System Package Updates
**File**: `playbooks/update.yml`

Updates all packages on all systems with notification support.

**Usage**:
```bash
# Update all systems
ansible-playbook -i inventory/hosts.yml playbooks/update.yml

# Update specific group
ansible-playbook -i inventory/hosts.yml playbooks/update.yml --limit all_raspberry_pi

# Update with auto-reboot
ansible-playbook -i inventory/hosts.yml playbooks/update.yml -e "auto_reboot=true"
```

## Utility Playbooks

Located in `playbooks/utilities/`:

- **reboot.yml** - Reboot systems in a controlled manner
- **monitoring.yml** - Monitor system health and send alerts
- **test-notifications.yml** - Test ntfy notification system

## Secrets Management

**Best Practice:** All secrets are stored in `playbooks/vars/` and encrypted with Ansible Vault.

### Directory structure

```
playbooks/
├── vars/
│   ├── grafana_secrets.yml     # Grafana admin credentials
│   ├── homepage_secrets.yml    # Homepage API keys
│   ├── immich_secrets.yml      # Immich PostgreSQL credentials
│   ├── media_secrets.yml       # Mullvad VPN credentials
│   ├── paperless_secrets.yml   # Paperless admin + DB credentials
│   ├── plane_secrets.yml       # Plane configuration
│   └── traefik_secrets.yml     # Cloudflare API token
└── deploy.yml
```

### Vault files by playbook

| Playbook | Vault Files |
|----------|-------------|
| `core.yml` | `traefik_secrets.yml` |
| `observability.yml` | `grafana_secrets.yml` |
| `dashboards.yml` | `homepage_secrets.yml` |
| `applications.yml` | `plane_secrets.yml`, `media_secrets.yml`, `paperless_secrets.yml`, `immich_secrets.yml` |

### Creating/editing secrets

1. Create a vars file with your secrets:
   ```bash
   cat > playbooks/vars/my_secrets.yml <<EOF
   my_api_key: "secret-value"
   my_password: "another-secret"
   EOF
   ```

2. Encrypt with Ansible Vault:
   ```bash
   ansible-vault encrypt playbooks/vars/my_secrets.yml
   ```

3. Edit encrypted file:
   ```bash
   ansible-vault edit playbooks/vars/my_secrets.yml
   ```

4. Run the playbook (uses vault password file if configured):
   ```bash
   ansible-playbook playbooks/deploy.yml
   ```

## Available Roles

### Infrastructure Roles

- **rpi_setup**: Configures Raspberry Pi nodes with iSCSI and cgroup settings
- **install_cert_manager**: Deploys cert-manager with Cloudflare DNS-01 ClusterIssuer for Let's Encrypt
- **configure_traefik_acme**: Configures Traefik Gateway API with cert-manager wildcard certificate
- **install_prometheus**: Deploys Prometheus (templates, standard Ingress with cert-manager)
- **install_victoria_metrics**: Deploys Victoria Metrics (templates, standard Ingress with cert-manager)
- **install_node_exporter**: Deploys Node Exporter DaemonSet for system metrics
- **install_grafana**: Deploys Grafana dashboard (templates, standard Ingress with cert-manager)
- **install_k8s_dashboard**: Deploys Kubernetes Dashboard with Helm (IngressRoute for HTTPS backend)
- **install_headlamp**: Deploys Headlamp Kubernetes UI (templates, standard Ingress with cert-manager)
- **install_homepage**: Deploys Homepage dashboard (templates, standard Ingress with cert-manager)

### Application Roles

- **install_jellyfin**: Deploys Jellyfin media server (templates, standard Ingress + Cloudflare tunnel)
- **install_media**: Deploys media stack - Sonarr, Radarr, qBittorrent, Jackett, SABnzbd (templates, standard Ingress with cert-manager, Mullvad VPN via gluetun)
- **install_plane**: Deploys Plane project management (templates, standard Ingress with cert-manager)
- **install_paperless**: Deploys Paperless-ngx document management (Cloudflare tunnel for external access)
- **install_immich**: Deploys Immich photo management with ML-powered search (templates, standard Ingress with cert-manager)
- **install_portainer**: Deploys Portainer container management (IngressRoute for HTTPS backend)

## Role Structure

Most roles follow a template-based structure for maximum configurability:

```
roles/install_example/
├── defaults/
│   └── main.yml           # Default variables (namespace, versions, resources, hosts)
├── templates/
│   ├── storage.yaml.j2    # PV/PVC definitions
│   ├── app.yaml.j2        # Deployment and Service
│   ├── secret.yaml.j2     # Kubernetes Secret (values from vault)
│   ├── certificate.yaml.j2 # cert-manager Certificate
│   └── ingress.yaml.j2    # Standard Kubernetes Ingress
└── tasks/
    └── main.yml           # Ansible tasks using templates
```

### Key Conventions

- **Templates over static files**: Use Jinja2 templates in `templates/` for all Kubernetes resources
- **Variables in defaults**: All configurable values go in `defaults/main.yml`
- **Secrets via Ansible Vault**: Secret values come from `playbooks/vars/*_secrets.yml` (vault-encrypted)
- **Standard Ingress**: Use `networking.k8s.io/v1` Ingress with cert-manager Certificate (not IngressRoute)
- **Use `from_yaml_all` for multi-document templates**: `loop: "{{ lookup('template', 'file.yaml.j2') | from_yaml_all | list }}"`

## Traefik Routing Configuration

This cluster uses Traefik as the ingress controller with multiple routing options.

### Routing Options Comparison

| Option | Standard | TLS | HTTPS Backends | Portability |
|--------|----------|-----|----------------|-------------|
| **Ingress** | Kubernetes v1 | Via cert-manager Certificate | No | Best |
| **HTTPRoute** | Gateway API | Via Gateway certificateRefs | Limited | Good |
| **IngressRoute** | Traefik CRD | Via secretName | Yes (ServersTransport) | Traefik only |

### When to Use Each

**Use standard Ingress** (recommended for most services):
- Maximum Kubernetes portability
- Each service gets its own cert-manager Certificate
- Used by: Jellyfin, Media stack, Headlamp, Homepage, Grafana, Prometheus, Victoria Metrics, Plane

**Use IngressRoute** for:
- Services with HTTPS backends that use self-signed certificates
- When you need ServersTransport for `insecureSkipVerify`
- Used by: Kubernetes Dashboard, Portainer

**Use Cloudflare Tunnel** for:
- Services that need external access outside the corp network
- Used by: Jellyfin (external), Paperless, Kaneo

### Standard Ingress with cert-manager (Recommended)

For most services, use standard Kubernetes Ingress with a dedicated cert-manager Certificate:

```yaml
# Certificate - requests TLS cert from Let's Encrypt
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-app-tls
  namespace: my-namespace
spec:
  secretName: my-app-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - my-app.corp.mulliken.net
---
# Standard Kubernetes Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: my-namespace
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - my-app.corp.mulliken.net
      secretName: my-app-tls
  rules:
    - host: my-app.corp.mulliken.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-service
                port:
                  number: 80
```

### Gateway API Limitation with HTTPS Backends

Traefik's Gateway API implementation does not fully support HTTPS backend configuration:

- **BackendTLSPolicy** is incomplete in Traefik (as of v3.x)
- Service annotations like `traefik.io/service.serversscheme` don't work with Gateway API
- The error manifests as: `parsing service annotations config: decoding labels: field not found, node: serversscheme`

For HTTPS backends with self-signed certificates, use IngressRoute with ServersTransport:

```yaml
# ServersTransport for skipping TLS verification
apiVersion: traefik.io/v1alpha1
kind: ServersTransport
metadata:
  name: my-transport
  namespace: my-namespace
spec:
  insecureSkipVerify: true
---
# IngressRoute referencing the ServersTransport
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: my-namespace
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`my-app.corp.mulliken.net`)
      kind: Rule
      services:
        - name: my-app-service
          port: 443
          serversTransport: my-transport
  tls:
    secretName: wildcard-corp-tls
```

### TLS Certificates with cert-manager

The cluster uses cert-manager with Cloudflare DNS-01 challenge for Let's Encrypt certificates.

**Key resources:**
- `ClusterIssuer`: `letsencrypt-prod` (in cert-manager namespace)
- `Certificate`: `wildcard-corp-tls` (in kube-system, referenced by Gateway)
- Wildcard domains: `*.corp.mulliken.net`

**Roles:**
- `install_cert_manager` - Installs cert-manager and creates ClusterIssuer
- `configure_traefik_acme` - Configures Traefik Gateway with cert-manager certificate

**Note:** cert-manager uses external DNS servers (1.1.1.1, 8.8.8.8) for DNS propagation checks because CoreDNS cannot resolve external domains for the ACME challenge.

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

### Issue: Gateway API HTTPRoute returns 500 for HTTPS backend

**Error in Traefik logs**:
```
tls: failed to verify certificate: x509: cannot validate certificate for [IP] because it doesn't contain any IP SANs
```
or
```
parsing service annotations config: decoding labels: field not found, node: serversscheme
```

**Solution**: Traefik's Gateway API provider doesn't support HTTPS backends with self-signed certificates. Use IngressRoute with ServersTransport instead. See the "Traefik Routing Configuration" section above.

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

Before deploying Grafana, configure the admin credentials in the vault file:

1. **Edit the secrets file**:
   ```bash
   ansible-vault edit playbooks/vars/grafana_secrets.yml
   ```

2. **Set your credentials**:
   ```yaml
   grafana_admin_user: "admin"
   grafana_admin_password: "your-secure-password-here"
   ```

3. **Deploy the stack**:
   ```bash
   # Deploy only the observability stack
   ansible-playbook -i inventory/hosts.yml playbooks/observability.yml

   # Or deploy the full infrastructure
   ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml
   ```

### Accessing the Dashboards

#### Grafana

```bash
# Port forward to access Grafana
kubectl -n monitoring port-forward svc/grafana 3000:3000

# Access at: http://localhost:3000
# Login with the credentials from playbooks/vars/grafana_secrets.yml
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

#### Grafana won't start - missing secret

**Error**: Pod fails with secret mount errors

**Solution**: Ensure `playbooks/vars/grafana_secrets.yml` exists and is encrypted with ansible-vault

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

1. Edit the vault file: `ansible-vault edit playbooks/vars/grafana_secrets.yml`
2. Re-run the playbook: `ansible-playbook -i inventory/hosts.yml playbooks/observability.yml --tags grafana`
3. Restart Grafana: `kubectl rollout restart -n monitoring deployment/grafana`

## Media Stack with Mullvad VPN

The media role deploys Sonarr (TV), Radarr (movies), qBittorrent (downloads), Jackett (indexers), and SABnzbd (Usenet). Download traffic is routed through Mullvad VPN using a gluetun sidecar container.

**Note:** The media stack uses the `sonarr` namespace for backward compatibility with existing PVCs.

### Architecture

- **Sonarr/Radarr**: PVR applications (no VPN, direct internet access)
- **Downloads pod**: qBittorrent, Jackett, SABnzbd, FlareSolverr (all traffic through Mullvad VPN via gluetun)
- **Storage**: NFS for media (shared with Jellyfin), Longhorn for configs

### Ingress URLs

All services are accessible via standard Ingress with Let's Encrypt TLS:
- Sonarr: https://sonarr.corp.mulliken.net
- Radarr: https://radarr.corp.mulliken.net
- qBittorrent: https://qbittorrent.corp.mulliken.net
- Jackett: https://jackett.corp.mulliken.net
- SABnzbd: https://sabnzbd.corp.mulliken.net

### Initial Setup

1. **Get Mullvad WireGuard credentials**:
   - Log in to https://mullvad.net/account
   - Navigate to "WireGuard configuration"
   - Generate a new WireGuard key if needed
   - Note your private key and IP addresses

2. **Configure the vault file**:
   ```bash
   ansible-vault edit playbooks/vars/media_secrets.yml
   ```

   Set your credentials:
   ```yaml
   media_wireguard_private_key: "your_private_key_here"
   media_wireguard_addresses: "10.x.x.x/32,fc00:bbbb:bbbb:bb01::x:xxxx/128"
   ```

3. **Deploy the media stack**:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags media
   ```

### Accessing Services

All services are available via Ingress or port-forward:

```bash
# Sonarr (TV shows)
kubectl -n sonarr port-forward svc/sonarr 8989:8989
# Access at: http://localhost:8989

# Radarr (Movies)
kubectl -n sonarr port-forward svc/radarr 7878:7878
# Access at: http://localhost:7878

# qBittorrent (Downloads)
kubectl -n sonarr port-forward svc/downloads 8080:8080
# Access at: http://localhost:8080

# Jackett (Indexers)
kubectl -n sonarr port-forward svc/downloads 9117:9117
# Access at: http://localhost:9117

# SABnzbd (Usenet)
kubectl -n sonarr port-forward svc/downloads 8085:8085
# Access at: http://localhost:8085
```

### Verifying VPN Connection

```bash
# Check VPN public IP
kubectl exec -n sonarr deployment/downloads -c gluetun -- wget -qO- http://localhost:8000/v1/publicip/ip

# Check VPN logs
kubectl logs -n sonarr deployment/downloads -c gluetun
```

## Jellyfin Media Server

Jellyfin is deployed with dual access methods:
- **Internal**: Standard Ingress at https://jellyfin.corp.mulliken.net (cert-manager TLS)
- **External**: Cloudflare tunnel at https://jellyfin.mulliken.net

### Configuration

All settings are in `roles/install_jellyfin/defaults/main.yml`:
- `jellyfin_ingress_host`: Internal domain (corp.mulliken.net)
- `jellyfin_external_url`: External URL for Cloudflare tunnel
- `jellyfin_nfs_server`/`jellyfin_nfs_path`: NFS media storage location

### Accessing Jellyfin

```bash
# Via Ingress (internal)
https://jellyfin.corp.mulliken.net

# Via Cloudflare tunnel (external)
https://jellyfin.mulliken.net

# Via port-forward
kubectl -n jellyfin port-forward svc/jellyfin 8096:8096
# Access at: http://localhost:8096
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
2. Edit the vault file: `ansible-vault edit playbooks/vars/media_secrets.yml`
3. Re-run the playbook:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags media
   kubectl rollout restart -n sonarr deployment/downloads
   ```

## Paperless-ngx Document Management

Paperless-ngx is a document management system that scans, indexes, and archives your documents. The install_paperless role deploys Paperless with PostgreSQL, Redis, and optional Proton Mail Bridge integration for email consumption.

### Architecture

- **PostgreSQL**: Database for document metadata
- **Redis**: Message broker for async tasks
- **Paperless-ngx**: Main application (port 8000)
- **Proton Mail Bridge** (optional): IMAP/SMTP sidecar for email integration
- **Cloudflared**: Tunnel for secure external access

### Initial Setup

1. **Configure the vault file**:
   ```bash
   ansible-vault edit playbooks/vars/paperless_secrets.yml
   ```

   Set your credentials:
   ```yaml
   paperless_postgres_user: "paperless"
   paperless_postgres_password: "generate-secure-password"
   paperless_admin_user: "admin"
   paperless_admin_password: "your-admin-password"
   paperless_admin_email: "admin@example.com"
   paperless_secret_key: "generate-with-openssl-rand-base64-64"
   ```

2. **Deploy Paperless**:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags paperless
   ```

### Accessing Paperless

```bash
# Port forward to access Paperless
kubectl -n paperless port-forward svc/paperless 8000:8000

# Access at: http://localhost:8000
# Login with the admin credentials from playbooks/vars/paperless_secrets.yml
```

### Proton Mail Bridge Setup (Optional)

The Proton Mail Bridge runs as a sidecar container, providing IMAP (port 1143) and SMTP (port 1025) to Paperless for email consumption. This allows Paperless to automatically import documents sent to your email.

#### Step 1: Initialize the Bridge

The bridge requires interactive login first. Run an init pod to authenticate:

```bash
# Create a temporary pod to initialize the bridge
kubectl run proton-bridge-init -n paperless -it --rm \
  --image=shenxn/protonmail-bridge:build \
  --overrides='{"spec":{"containers":[{"name":"proton-bridge-init","image":"shenxn/protonmail-bridge:build","command":["protonmail-bridge","--cli"],"stdin":true,"tty":true,"volumeMounts":[{"name":"data","mountPath":"/root"}]}],"volumes":[{"name":"data","persistentVolumeClaim":{"claimName":"proton-bridge-pvc"}}]}}' \
  -- init
```

**Note**: The PVC must exist first. Deploy with `paperless_email_enabled: true` in defaults to create it, then run the init.

#### Step 2: Login and Get Credentials

In the bridge CLI:

```
>>> login
Username: your-proton-email@protonmail.com
Password: your-proton-password
# Complete 2FA if enabled

>>> info
# Note the "Password" shown - this is the bridge-generated password
# NOT your Proton account password!

>>> exit
```

#### Step 3: Configure Secrets

Add the bridge credentials to your vault file:

```bash
ansible-vault edit playbooks/vars/paperless_secrets.yml
```

```yaml
# Your Proton email address
paperless_proton_email: "your-proton-email@protonmail.com"

# The bridge-generated password from 'info' command
paperless_proton_bridge_password: "bridge-generated-password-here"
```

#### Step 4: Enable Email and Redeploy

1. Edit `roles/install_paperless/defaults/main.yml`:
   ```yaml
   paperless_email_enabled: true
   ```

2. Redeploy:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags paperless
   ```

### Configuring Email Rules in Paperless

After deployment, configure email consumption in Paperless:

1. Access Paperless web UI
2. Go to **Settings** → **Mail**
3. Add a mail account:
   - **Name**: Proton Mail
   - **IMAP Server**: localhost (sidecar handles this)
   - **IMAP Port**: 1143
   - **IMAP Security**: None (internal traffic)
   - **Username**: Your Proton email
   - **Password**: Bridge-generated password
4. Create mail rules to specify which folders/senders to import from

### Troubleshooting

#### Bridge won't connect

Check the bridge logs:
```bash
kubectl logs -n paperless deployment/paperless -c proton-bridge
```

#### Re-initialize the bridge

If you need to re-authenticate:
```bash
# Delete the existing PVC data
kubectl delete pvc proton-bridge-pvc -n paperless

# Redeploy to recreate PVC
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure-deploy-complete.yml --tags paperless

# Run init again (see Step 1)
```

#### Paperless can't connect to bridge

Verify the bridge is ready:
```bash
# Check if IMAP port is responding
kubectl exec -n paperless deployment/paperless -c proton-bridge -- nc -zv localhost 1143
```

## Notes

- The deprecated `k8s` role has been split into individual application-specific roles
- Always use the inventory file with `-i inventory/hosts.yml` for playbooks that target remote hosts
- Roles are idempotent and safe to run multiple times
- Check the PLAY RECAP at the end of each run to verify success
- Old playbooks have been archived to `playbooks/archive/` and consolidated into `deploy.yml`
- Most roles now use Jinja2 templates instead of static YAML files for better configurability
- Standard Kubernetes Ingress with cert-manager is preferred over Traefik IngressRoute for portability
- The media stack uses namespace `sonarr` (not `media`) for backward compatibility with existing PVCs
- All secrets are managed via Ansible Vault in `playbooks/vars/` - no more Sealed Secrets

## Getting Help

If you encounter issues not covered here, check:
- Playbook documentation: `playbooks/README.md`
- Inventory documentation: `inventory/README.md`
- Ansible output for specific error messages
- Kubernetes pod logs: `kubectl logs -n <namespace> <pod-name>`
- Role documentation in `roles/<role-name>/README.md` (if available)
