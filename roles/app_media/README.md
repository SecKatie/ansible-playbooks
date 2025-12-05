# Ansible Role: install_sonarr

Deploys Sonarr PVR (Personal Video Recorder) for TV shows with Mullvad VPN protection via gluetun sidecar container.

## Description

This role installs Sonarr on Kubernetes with the following features:

- **Sonarr v4**: Modern PVR for managing and downloading TV shows
- **Mullvad VPN**: All Sonarr traffic routed through Mullvad WireGuard VPN using gluetun
- **Shared Storage**: Uses the same NFS media storage as Jellyfin for seamless integration
- **Sealed Secrets**: Secure credential management for VPN configuration
- **Health Checks**: Automatic monitoring of both Sonarr and VPN connectivity

## Architecture

```
┌─────────────────────────────────────┐
│         Sonarr Pod                  │
│                                     │
│  ┌──────────────┐  ┌─────────────┐ │
│  │   Sonarr     │  │   Gluetun   │ │
│  │ (App Logic)  │  │ (VPN Tunnel)│ │
│  │              │  │             │ │
│  │ Port: 8989   │  │ Port: 8000  │ │
│  └──────────────┘  └─────────────┘ │
│         │                 │         │
│         └────────┬────────┘         │
│                  │                  │
│           All traffic flows         │
│          through VPN tunnel         │
└─────────────────────────────────────┘
              │
              ├─ Config (Local): 10Gi
              └─ Media (NFS): Shared with Jellyfin
```

## Requirements

### Kubernetes Cluster
- Kubernetes 1.19+
- kubectl configured with cluster access
- StorageClass for local storage (default)
- NFS StorageClass: `nfs-media` (shared with Jellyfin)

### Dependencies
- `kubernetes.core` Ansible collection
- Sealed Secrets controller deployed (via `install_kubeseal` role)

### Mullvad Account
- Active Mullvad VPN subscription
- WireGuard configuration credentials

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Sonarr version
sonarr_version: "4.0.11"

# Gluetun version
gluetun_version: "v3.39.1"

# Namespace
sonarr_namespace: "sonarr"

# Resource requests and limits
sonarr_cpu_request: "200m"
sonarr_memory_request: "512Mi"
sonarr_cpu_limit: "2000m"
sonarr_memory_limit: "2Gi"

gluetun_cpu_request: "100m"
gluetun_memory_request: "128Mi"
gluetun_cpu_limit: "500m"
gluetun_memory_limit: "512Mi"

# Storage sizes
sonarr_config_storage: "10Gi"
sonarr_media_storage: "1Ti"

# Timezone
sonarr_timezone: "America/New_York"
```

## Setup Instructions

### 1. Get Mullvad WireGuard Credentials

1. Log in to your Mullvad account at https://mullvad.net/
2. Navigate to "WireGuard configuration"
3. Generate a new WireGuard key
4. Note your private key and IP addresses

### 2. Create Sealed Secret

Create your VPN credentials secret:

```bash
# Copy the example template
cat > /tmp/sonarr-vpn-secrets.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: sonarr-vpn-secrets
  namespace: sonarr
type: Opaque
stringData:
  WIREGUARD_PRIVATE_KEY: "YOUR_PRIVATE_KEY_HERE"
  WIREGUARD_ADDRESSES: "10.x.x.x/32"
  SERVER_CITIES: "New York NY"
EOF

# Seal the secret
kubeseal --format=yaml < /tmp/sonarr-vpn-secrets.yaml > roles/install_sonarr/files/sealedsecrets.yaml

# Remove the temporary file
rm /tmp/sonarr-vpn-secrets.yaml
```

### 3. Deploy Sonarr

Add the role to your playbook:

```yaml
- name: Install Sonarr with Mullvad VPN
  hosts: localhost
  roles:
    - install_sonarr
```

Run the playbook:

```bash
ansible-playbook playbooks/your-playbook.yml
```

## Accessing Sonarr

### Via Port Forward

```bash
kubectl -n sonarr port-forward svc/sonarr 8989:8989
```

Then access: http://localhost:8989

### Internal Access

From within the cluster:
```
http://sonarr.sonarr.svc.cluster.local:8989
```

## Configuration

### Media Paths in Sonarr

Configure Sonarr with these paths to integrate with Jellyfin:

- **Root Folder for TV Shows**: `/media/tv`
- **Download Client Path**: `/media/downloads`

### Directory Structure on NFS

The NFS share should be organized as:

```
/volume2/media/
├── tv/              # TV shows library
│   ├── Show Name/
│   └── Another Show/
├── downloads/       # Download client output
│   ├── complete/
│   └── incomplete/
└── movies/          # For other services (Radarr, etc.)
```

## VPN Verification

Check VPN status:

```bash
# Get the VPN public IP
kubectl exec -n sonarr deployment/sonarr -c gluetun -- wget -qO- http://localhost:8000/v1/publicip/ip

# Check VPN logs
kubectl logs -n sonarr deployment/sonarr -c gluetun

# Check Sonarr logs
kubectl logs -n sonarr deployment/sonarr -c sonarr
```

## Troubleshooting

### Sonarr Won't Start

Check if VPN is connected:
```bash
kubectl logs -n sonarr deployment/sonarr -c gluetun | grep -i "connected"
```

### VPN Connection Failed

1. Verify sealed secret is correct:
```bash
kubectl get secret -n sonarr sonarr-vpn-secrets -o yaml
```

2. Check gluetun logs:
```bash
kubectl logs -n sonarr deployment/sonarr -c gluetun -f
```

3. Common issues:
   - Invalid WireGuard private key
   - Incorrect IP addresses format
   - Mullvad account expired

### Storage Issues

Check PVC status:
```bash
kubectl get pvc -n sonarr
```

Verify NFS mount:
```bash
kubectl exec -n sonarr deployment/sonarr -c sonarr -- ls -la /media
```

## Integration with Jellyfin

Sonarr and Jellyfin share the same NFS media storage:

1. **Sonarr** downloads and organizes TV shows to `/media/tv`
2. **Jellyfin** reads from the same path at `/media/tv`
3. No manual file copying needed - automatic integration

To add Sonarr's TV library to Jellyfin:
1. Open Jellyfin
2. Go to Dashboard → Libraries
3. Add a new library:
   - Type: TV Shows
   - Folder: `/media/tv`

## Security Considerations

- All Sonarr traffic (including API calls and downloads) routes through Mullvad VPN
- VPN credentials stored as Sealed Secrets (encrypted at rest)
- Firewall rules restrict VPN container to only allow necessary traffic
- Non-root containers with security contexts enabled

## License

MIT

## Author Information

Created for Kubernetes-based media server deployments.
