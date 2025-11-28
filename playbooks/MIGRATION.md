# Playbook Migration Guide

This document explains the changes made to consolidate and simplify the playbook structure.

## What Changed?

### Before (Old Structure)
```
playbooks/
├── infrastructure-deploy-complete.yml
├── install_k8s_apps.yml
├── infrastructure-install-nfs-support.yml
├── k3s-join-agents.yml
├── disable-ipv6.yml
├── maintenance-update-packages.yml
├── maintenance-reboot-systems.yml
├── monitoring-system-health.yml
└── testing-notification-system.yml
```

### After (New Structure)
```
playbooks/
├── deploy.yml                         # Consolidated deployment
├── update.yml                         # System updates
├── utilities/
│   ├── reboot.yml                     # System reboots
│   ├── monitoring.yml                 # Health monitoring
│   └── test-notifications.yml        # Notification testing
└── archive/                           # Old playbooks (deprecated)
```

## Migration Path

### Old Command → New Command

#### Infrastructure Deployment
```bash
# OLD
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure-deploy-complete.yml

# NEW
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml
```

#### Kubernetes Apps Only
```bash
# OLD
ansible-playbook playbooks/install_k8s_apps.yml

# NEW
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags "core,dashboards"
```

#### NFS Support Installation
```bash
# OLD
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure-install-nfs-support.yml

# NEW
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags nfs
```

#### Join K3s Agents
```bash
# OLD
ansible-playbook -i inventory/hosts.yml playbooks/k3s-join-agents.yml

# NEW
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags k3s_agents
```

#### Disable IPv6
```bash
# OLD
ansible-playbook -i inventory/hosts.yml playbooks/disable-ipv6.yml

# NEW (note: ipv6 tag uses 'never' so must be explicitly included)
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags ipv6
```

#### System Updates
```bash
# OLD
ansible-playbook -i inventory/hosts.yml playbooks/maintenance-update-packages.yml

# NEW
ansible-playbook -i inventory/hosts.yml playbooks/update.yml
```

#### System Reboot
```bash
# OLD
ansible-playbook -i inventory/hosts.yml playbooks/maintenance-reboot-systems.yml

# NEW
ansible-playbook -i inventory/hosts.yml playbooks/utilities/reboot.yml
```

#### System Monitoring
```bash
# OLD
ansible-playbook -i inventory/hosts.yml playbooks/monitoring-system-health.yml

# NEW
ansible-playbook -i inventory/hosts.yml playbooks/utilities/monitoring.yml
```

#### Test Notifications
```bash
# OLD
ansible-playbook playbooks/testing-notification-system.yml

# NEW
ansible-playbook playbooks/utilities/test-notifications.yml
```

## Benefits of New Structure

1. **Single Source of Truth**: One main deployment playbook instead of multiple overlapping ones
2. **Granular Control**: Use tags to deploy exactly what you need
3. **Better Organization**: Clear separation of deployment, maintenance, and utilities
4. **Reduced Duplication**: No more copying role lists between playbooks
5. **Easier Maintenance**: Update once in deploy.yml instead of multiple files

## Selective Deployment Examples

The new structure makes it easy to deploy just what you need:

```bash
# Deploy only infrastructure
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags infrastructure

# Deploy only a specific app
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags jellyfin

# Deploy observability stack
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags observability

# Deploy multiple specific components
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml --tags "storage,security,networking"
```

## What to Do with Old Playbooks

The old playbooks have been moved to `playbooks/archive/` but are **deprecated** and should not be used. They are kept for reference only.

If you have scripts or documentation referencing old playbooks, update them to use the new structure.

## Need Help?

- See `playbooks/README.md` for complete documentation
- Check `CLAUDE.md` for role-specific documentation
- Run with `--list-tags` to see all available tags:
  ```bash
  ansible-playbook playbooks/deploy.yml --list-tags
  ```
