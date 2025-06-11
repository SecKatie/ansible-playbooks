# System Update Role

This Ansible role updates system packages across different Linux distributions including:
- Debian/Ubuntu (using apt)
- RHEL/CentOS/Fedora (using yum/dnf)
- Arch Linux (using pacman)
- SUSE (using zypper)

## Features

- Automatically detects the Linux distribution and uses the appropriate package manager
- Updates package cache before upgrading
- Performs full system package upgrade
- Removes unnecessary packages and cleans cache (configurable)
- Checks if a reboot is required after updates
- Logs update completion timestamps
- Supports various configuration options through variables

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Whether to automatically reboot if required after updates
auto_reboot: false

# Time to wait before rebooting (seconds)
reboot_delay: 30

# Log file for update history
update_log_file: /var/log/ansible-updates.log

# Whether to perform a full distribution upgrade (dist-upgrade)
full_upgrade: true

# Whether to remove unnecessary packages after upgrade
autoremove: true

# Whether to clean package cache after upgrade
autoclean: true
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  become: yes
  roles:
    - system_update
```

With custom variables:

```yaml
- hosts: all
  become: yes
  roles:
    - role: system_update
      vars:
        auto_reboot: true
        reboot_delay: 60
```

## License

MIT

## Author Information

This role was created for system maintenance automation. 