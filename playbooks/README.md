# Ansible Playbooks

This directory contains Ansible playbooks for deploying and managing the Kubernetes infrastructure and applications.

## Directory Structure

```
playbooks/
├── README.md                          # This file
├── deploy.yml                         # Main deployment playbook
├── update.yml                         # System update playbook
├── vars/                              # Variables and secrets
│   └── homepage_secrets.yml
├── utilities/                         # Utility playbooks
│   ├── reboot.yml                     # Reboot systems
│   ├── monitoring.yml                 # System health monitoring
│   └── test-notifications.yml        # Test ntfy notifications
└── archive/                           # Archived/deprecated playbooks
```

## Main Playbooks

### 🚀 deploy.yml - Complete Infrastructure Deployment

The primary playbook for deploying the entire infrastructure stack.

**What it does:**
- Configures Raspberry Pi nodes (iSCSI, cgroups, NFS)
- Joins RHEL nodes to K3s cluster
- Deploys Kubernetes core components (Longhorn, Sealed Secrets, Traefik)
- Installs observability stack (Victoria Metrics, Grafana, Node Exporter)
- Deploys dashboards (Kubernetes Dashboard, Homepage)
- Installs applications (Jellyfin, Media stack, Paperless, Kaneo)

**Usage:**

```bash
# Deploy everything
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml

# Deploy only infrastructure components
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags infrastructure

# Deploy only Kubernetes core components
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags core

# Deploy only observability stack
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags observability

# Deploy only applications
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags applications

# Deploy specific application
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags jellyfin
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags media
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags paperless

# Skip certain components
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --skip-tags ipv6
```

**Available Tags:**

| Tag | Description |
|-----|-------------|
| `infrastructure` | Base infrastructure setup (Pi config, NFS, IPv6) |
| `rpi` | Raspberry Pi specific configuration |
| `nfs` | NFS support installation |
| `ipv6` | IPv6 disabling (tagged with `never`, must be explicitly included) |
| `k3s` | K3s cluster configuration |
| `k3s_agents` | Join K3s agents to cluster |
| `storage` | Storage solutions (Longhorn) |
| `security` | Security components (Sealed Secrets) |
| `networking` | Networking components (Traefik with ACME/TLS) |
| `observability` | Monitoring stack (Victoria Metrics, Grafana, Node Exporter) |
| `dashboards` | Dashboard applications (K8s Dashboard, Homepage) |
| `applications` | All user-facing applications |
| `jellyfin` | Jellyfin media server |
| `media` | Media management stack (Sonarr, Radarr, qBittorrent, Jackett) |
| `paperless` | Paperless-ngx document management |
| `kaneo` | Kaneo project management |

**Tag Combinations:**

```bash
# Deploy infrastructure and core components only
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags "infrastructure,core"

# Deploy observability and dashboards
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags "observability,dashboards"

# Deploy all media-related services
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags "jellyfin,media"
```

### 📦 update.yml - System Package Updates

Updates all packages on all systems with notification support.

**What it does:**
- Updates system packages on all hosts
- Checks if reboot is required
- Sends notifications via ntfy (optional)
- Provides detailed update summary

**Usage:**

```bash
# Update all systems
ansible-playbook -i inventory/hosts.yml playbooks/update.yml

# Update specific group
ansible-playbook -i inventory/hosts.yml playbooks/update.yml --limit all_raspberry_pi
ansible-playbook -i inventory/hosts.yml playbooks/update.yml --limit rhel_k3s_agents

# Update with auto-reboot enabled
ansible-playbook -i inventory/hosts.yml playbooks/update.yml -e "auto_reboot=true"

# Update systems serially (one at a time)
ansible-playbook -i inventory/hosts.yml playbooks/update.yml -e "update_serial=1"
```

**Variables:**

- `auto_reboot`: Automatically reboot if required (default: `false`)
- `reboot_delay`: Seconds to wait before rebooting (default: `30`)
- `update_serial`: How many hosts to update at once (default: `100%`)
- `ntfy_topic`: ntfy topic for notifications
- `ntfy_auth`: ntfy authentication token

## Utility Playbooks

### 🔄 utilities/reboot.yml - System Reboot

Reboots systems in a controlled manner.

**Usage:**

```bash
# Reboot all servers
ansible-playbook -i inventory/hosts.yml playbooks/utilities/reboot.yml

# Reboot specific hosts
ansible-playbook -i inventory/hosts.yml playbooks/utilities/reboot.yml --limit super6c_node_1
```

### 📊 utilities/monitoring.yml - System Health Monitoring

Monitors system health and sends alerts via ntfy.

**What it monitors:**
- Disk usage
- Memory usage
- Critical service status

**Usage:**

```bash
# Monitor all systems
ansible-playbook -i inventory/hosts.yml playbooks/utilities/monitoring.yml

# Monitor with custom thresholds
ansible-playbook -i inventory/hosts.yml playbooks/utilities/monitoring.yml \
  -e "disk_threshold=90" \
  -e "memory_threshold=95"

# Monitor specific group
ansible-playbook -i inventory/hosts.yml playbooks/utilities/monitoring.yml --limit k3s_cluster
```

**Variables:**

- `disk_threshold`: Disk usage percentage to trigger alert (default: `80`)
- `memory_threshold`: Memory usage percentage to trigger alert (default: `90`)
- `ntfy_topic`: ntfy topic for notifications (default: `server_monitoring`)

### 🔔 utilities/test-notifications.yml - Test ntfy Notifications

Tests the ntfy notification system with various notification types.

**Usage:**

```bash
# Test notifications
ansible-playbook playbooks/utilities/test-notifications.yml

# Test with custom topic
ansible-playbook playbooks/utilities/test-notifications.yml -e "ntfy_topic=my-topic"
```

## Common Workflows

### Initial Setup

```bash
# 1. Deploy infrastructure and K3s cluster
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags "infrastructure,k3s"

# 2. Deploy core Kubernetes components
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags "core"

# 3. Deploy observability stack
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags observability

# 4. Deploy applications
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags applications
```

### Adding a New Application

```bash
# Deploy just the new application
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags <app-tag>
```

### Updating Systems

```bash
# Update all systems
ansible-playbook -i inventory/hosts.yml playbooks/update.yml

# Check for systems requiring reboot
ansible-playbook -i inventory/hosts.yml playbooks/utilities/monitoring.yml

# Reboot if needed
ansible-playbook -i inventory/hosts.yml playbooks/utilities/reboot.yml
```

### Rebuilding a Component

```bash
# Delete the component in Kubernetes
kubectl delete namespace <namespace>

# Redeploy
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags <component-tag>
```

## Best Practices

### 1. Always Use the Inventory File

```bash
# ✅ Correct
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml

# ❌ Wrong
ansible-playbook playbooks/deploy.yml
```

### 2. Test with --check Mode First

```bash
# Dry-run to see what would change
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --check
```

### 3. Limit Scope When Testing

```bash
# Test on a single host first
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --limit super6c_node_1
```

### 4. Use Tags for Selective Deployment

```bash
# Only deploy what you need
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags jellyfin
```

### 5. Check Logs for Errors

```bash
# View recent Ansible logs
tail -f /var/log/ansible.log  # if configured

# Check Kubernetes pod logs
kubectl logs -n <namespace> <pod-name>
```

## Troubleshooting

### Playbook Fails on Raspberry Pi Nodes

**Issue:** Connection or permission errors

**Solution:**
1. Verify SSH access: `ssh pi@172.16.10.246`
2. Check inventory: `ansible-inventory -i inventory/hosts.yml --list`
3. Test connectivity: `ansible -i inventory/hosts.yml all_raspberry_pi -m ping`

### Kubernetes Resources Not Creating

**Issue:** Playbook completes but resources don't appear

**Solution:**
1. Check if kubectl is configured: `kubectl get nodes`
2. Verify kubeconfig: `echo $KUBECONFIG`
3. Check role files exist: `ls roles/<role-name>/files/`

### Sealed Secrets Not Unsealing

**Issue:** Sealed secrets created but not decrypted

**Solution:**
1. Verify sealed-secrets controller is running: `kubectl get pods -n kube-system | grep sealed-secrets`
2. Check controller logs: `kubectl logs -n kube-system deployment/sealed-secrets-controller`
3. Recreate sealed secret if needed (see CLAUDE.md)

### Updates Hang or Timeout

**Issue:** Update playbook gets stuck

**Solution:**
1. Reduce parallelism: `-e "update_serial=1"`
2. Increase timeout in role if available
3. Run on smaller groups: `--limit all_raspberry_pi`

## Variables and Secrets

Some playbooks require variables files:

### homepage_secrets.yml

Required for Homepage dashboard deployment.

```yaml
---
# playbooks/vars/homepage_secrets.yml
homepage_secret_key: "your-secret-key-here"
# Add other Homepage configuration
```

Create this file before running deploy.yml with the `homepage` tag.

## Archived Playbooks

The `archive/` directory contains deprecated playbooks that have been consolidated into `deploy.yml`:

- `infrastructure-deploy-complete.yml` → `deploy.yml`
- `install_k8s_apps.yml` → `deploy.yml --tags core,dashboards`
- `infrastructure-install-nfs-support.yml` → `deploy.yml --tags nfs`
- `k3s-join-agents.yml` → `deploy.yml --tags k3s_agents`
- `disable-ipv6.yml` → `deploy.yml --tags ipv6` (with `never` tag)

These are kept for reference but should not be used in production.

## Related Documentation

- Main project documentation: `../CLAUDE.md`
- Inventory documentation: `../inventory/README.md`
- Role-specific documentation: `../roles/<role-name>/README.md` (if available)

## Need Help?

1. Check the main documentation: `../CLAUDE.md`
2. Review role documentation: `../roles/<role-name>/`
3. Check Ansible output for specific error messages
4. Review Kubernetes logs: `kubectl logs -n <namespace> <pod-name>`
5. Verify prerequisites are met (SSH access, kubeconfig, sealed-secrets, etc.)