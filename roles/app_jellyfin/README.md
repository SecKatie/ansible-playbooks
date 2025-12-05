# Jellyfin Kubernetes Deployment Role

This Ansible role deploys Jellyfin media server on Kubernetes with NFS storage and Cloudflare tunnel access.

## Features

- **Jellyfin Media Server**: Latest Jellyfin container with proper resource limits and health checks
- **NFS Media Storage**: Read-only access to media files from NFS server at `172.16.10.248:/volume2/media`
- **Persistent Config Storage**: Local storage for Jellyfin configuration and metadata
- **Cloudflare Tunnel**: Secure external access via Cloudflare tunnel
- **Security**: Non-root containers with proper security contexts

## Prerequisites

1. **Kubernetes cluster** with kubectl access
2. **Ansible** with `kubernetes.core` collection installed:
   ```bash
   ansible-galaxy collection install kubernetes.core
   ```
3. **NFS server** accessible at `172.16.10.248:/volume2/media`
4. **Cloudflare account** with tunnels enabled

## Storage Requirements

- **Media**: NFS mount from `172.16.10.248:/volume2/media` (read-only)
- **Config**: 50GB persistent volume for Jellyfin configuration and metadata

## Network Configuration

- **Internal Service**: `jellyfin.jellyfin.svc.cluster.local:8096`
- **External Access**: `https://jellyfin.mulliken.net` (via Cloudflare tunnel)
- **Ports**: 
  - 8096 (HTTP)
  - 8920 (HTTPS)
  - 1900 (DLNA UDP)
  - 7359 (Discovery UDP)

## Usage

### 1. Deploy the Role

```yaml
- hosts: localhost
  roles:
    - install_jellyfin
```

### 2. Create Cloudflare Tunnel

Before the tunnel pod will work, you need to:

1. **Create tunnel in Cloudflare dashboard**:
   - Name: `jellyfin-tunnel`
   - Note the tunnel ID and credentials file location

2. **Create tunnel credentials secret**:
   ```bash
   kubectl create secret generic jellyfin-tunnel-credentials \
     --from-file=credentials.json=/path/to/your/.cloudflared/<tunnel-id>.json \
     --namespace=jellyfin
   ```

3. **Configure DNS record**:
   - Add CNAME record: `jellyfin.mulliken.net` → `<tunnel-id>.cfargotunnel.com`

### 3. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n jellyfin

# Check services
kubectl get svc -n jellyfin

# Check persistent volumes
kubectl get pv,pvc -n jellyfin

# View logs
kubectl logs -n jellyfin deployment/jellyfin
kubectl logs -n jellyfin deployment/cloudflared
```

## Configuration Files

- `files/namespace.yaml`: Jellyfin namespace
- `files/storage.yaml`: PV and PVC definitions for NFS and local storage
- `files/jellyfin.yaml`: Jellyfin deployment and service
- `files/cloudflared.yaml`: Cloudflare tunnel deployment and configuration

## Customization

### Change NFS Server
Edit `files/storage.yaml` and modify:
```yaml
nfs:
  server: YOUR_NFS_SERVER_IP
  path: /your/media/path
```

### Change Domain
Edit `files/cloudflared.yaml` and `files/jellyfin.yaml`:
- Update `hostname` in cloudflared config
- Update `JELLYFIN_PublishedServerUrl` environment variable

### Resource Limits
Edit `files/jellyfin.yaml` to adjust CPU/memory limits:
```yaml
resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "2000m"
    memory: "4Gi"
```

## Troubleshooting

### NFS Mount Issues
```bash
# Check if NFS server is accessible from cluster nodes
showmount -e 172.16.10.248

# Test NFS mount manually on a node
sudo mount -t nfs 172.16.10.248:/volume2/media /mnt/test
```

### Cloudflare Tunnel Issues
```bash
# Check tunnel credentials secret exists
kubectl get secret jellyfin-tunnel-credentials -n jellyfin

# View cloudflared logs
kubectl logs -n jellyfin deployment/cloudflared

# Check tunnel status in Cloudflare dashboard
```

### Jellyfin Startup Issues
```bash
# Check Jellyfin logs
kubectl logs -n jellyfin deployment/jellyfin

# Check storage mounts
kubectl describe pod -n jellyfin -l app.kubernetes.io/name=jellyfin
```

## Security Notes

- Jellyfin runs as non-root user (UID 1000)
- Media storage is mounted read-only
- Cloudflare tunnel provides secure external access without exposing ports
- All containers have security contexts configured

## Access

- **External**: https://jellyfin.mulliken.net
- **Internal**: http://jellyfin.jellyfin.svc.cluster.local:8096

Initial setup will require accessing Jellyfin to configure media libraries pointing to `/media`. 