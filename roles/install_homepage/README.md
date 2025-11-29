# install_homepage

Deploys Homepage dashboard - a modern, customizable homepage for your server.

## Requirements

- Kubernetes cluster with kubectl configured
- Traefik ingress controller
- Longhorn storage class (for icons/images PVCs)

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `homepage_namespace` | `homepage` | Kubernetes namespace |
| `homepage_image` | `ghcr.io/gethomepage/homepage:latest` | Homepage container image |
| `homepage_cpu_request` | `10m` | CPU request |
| `homepage_cpu_limit` | `200m` | CPU limit |
| `homepage_memory_request` | `128Mi` | Memory request |
| `homepage_memory_limit` | `256Mi` | Memory limit |
| `homepage_ingress_enabled` | `true` | Enable Traefik IngressRoute |
| `homepage_ingress_host` | `homepage.corp.mulliken.net` | Ingress hostname |
| `homepage_icons_enabled` | `true` | Enable icons PVC |
| `homepage_icons_storage_class` | `longhorn` | Storage class for icons |
| `homepage_icons_storage_size` | `1Gi` | Icons PVC size |
| `homepage_images_enabled` | `true` | Enable images PVC |
| `homepage_images_storage_class` | `longhorn` | Storage class for images |
| `homepage_images_storage_size` | `1Gi` | Images PVC size |
| `homepage_background_image` | `/images/background.jpg` | Background image path or URL |

### Widget API Keys

Set these in `playbooks/vars/homepage_secrets.yml` (encrypted with ansible-vault):

| Variable | Description |
|----------|-------------|
| `homepage_jellyfin_api_key` | Jellyfin API key |
| `homepage_sonarr_api_key` | Sonarr API key |
| `homepage_radarr_api_key` | Radarr API key |
| `homepage_qbittorrent_username` | qBittorrent username |
| `homepage_qbittorrent_password` | qBittorrent password |
| `homepage_sabnzbd_api_key` | SABnzbd API key |
| `homepage_unifi_username` | UniFi username |
| `homepage_unifi_password` | UniFi password |

## Configuration

The dashboard is configured via the ConfigMap in `templates/configmap.yaml.j2`. Key sections:

- **settings.yaml**: Theme, layout, background, title
- **services.yaml**: Service entries with status monitoring and widgets
- **widgets.yaml**: Dashboard widgets (search, kubernetes, weather, etc.)
- **kubernetes.yaml**: Kubernetes integration settings

### Service Status Monitoring

Services can show status using either Kubernetes selectors or ping:

**Kubernetes selector** (for cluster services):
```yaml
- Jellyfin:
    icon: jellyfin
    href: https://jellyfin.corp.mulliken.net
    description: Media server
    namespace: jellyfin
    app: jellyfin
```

**Ping** (for external services):
```yaml
- Plane:
    icon: sh-plane
    href: https://plane.corp.mulliken.net
    description: Project management
    ping: plane.corp.mulliken.net
```

## Custom Icons and Background Images

The role creates two PVCs for custom assets:
- `/app/public/icons` - Custom service icons
- `/app/public/images` - Background images

### Adding Icons/Images

Use the provided script:

```bash
# Add a custom icon
./scripts/homepage-add-icon.sh /path/to/myicon.png

# Add a background image
./scripts/homepage-add-icon.sh -b /path/to/background.jpg

# List current assets
./scripts/homepage-add-icon.sh --list

# Delete an icon
./scripts/homepage-add-icon.sh --delete myicon.png

# Delete a background
./scripts/homepage-add-icon.sh --delete-bg background.jpg
```

Reference in the configmap:
- Icons: `icon: /icons/myicon.png`
- Background: `background: /images/background.jpg`

## Usage

```yaml
- hosts: localhost
  roles:
    - install_homepage
```

Or with the deploy playbook:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags dashboards --ask-vault-pass
```

## Customization

To customize the dashboard after deployment:

```bash
# Edit ConfigMap
kubectl edit configmap homepage-config -n homepage

# Restart to apply changes
kubectl rollout restart deployment/homepage -n homepage
```

## Access

- **Ingress**: https://homepage.corp.mulliken.net
- **Port-forward**: `kubectl -n homepage port-forward svc/homepage 3000:3000`

## Dependencies

None
