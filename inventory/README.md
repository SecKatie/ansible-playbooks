# Ansible Inventory Documentation

This directory contains the Ansible inventory configuration for the Kubernetes cluster and infrastructure.

## Directory Structure

```
inventory/
├── README.md                          # This file
├── hosts.yml                          # Main inventory file
└── group_vars/                        # Group-specific variables
    ├── k3s_control_plane.yml          # Control plane node settings
    ├── pi_k3s_agents.yml              # Raspberry Pi worker node settings
    ├── rhel_k3s_agents.yml            # RHEL worker node settings
    ├── vps_servers.yml                # VPS/cloud server settings
    └── all_raspberry_pi.yml           # Common Raspberry Pi settings
```

## Inventory Groups

### K3s Cluster Groups

#### `k3s_cluster`
Parent group containing all Kubernetes cluster nodes (control plane + agents).

#### `k3s_control_plane`
The K3s control plane (master) node running the K3s server.

- **super6c_node_1** (172.16.10.246)
  - User: `kglitchy`
  - Role: K3s control plane/master node

#### `k3s_agents`
Parent group for all K3s worker nodes (agents).

#### `pi_k3s_agents`
Raspberry Pi worker nodes running K3s agent.

- **super6c_node_2** (172.16.10.40) - User: `root`
- **super6c_node_3** (172.16.10.150) - User: `root`
- **super6c_node_4** (172.16.10.51) - User: `root`
- **super6c_node_5** (172.16.10.142) - User: `root`
- **super6c_node_6** (172.16.10.140) - User: `root`

#### `rhel_k3s_agents`
RHEL/Rocky Linux worker nodes running K3s agent.

- **rhel_node_1** (100.112.141.30) - User: `kmulliken`
- **rhel_node_2** (172.16.10.182) - User: `kmulliken`

### Infrastructure Groups

#### `vps_servers`
Virtual private servers and cloud instances.

- **rack_nerd_1** (66.63.163.116) - User: `root`

### Platform Groups

#### `all_raspberry_pi`
All Raspberry Pi devices across the infrastructure. This group includes both control plane and agent Pi nodes, useful for platform-specific tasks like:
- Raspberry Pi OS updates
- Hardware configuration
- Platform-specific package installation

## Using the Inventory

### Targeting Specific Groups

```bash
# Target only the control plane node
ansible-playbook -i inventory/hosts.yml playbook.yml --limit k3s_control_plane

# Target all K3s agents
ansible-playbook -i inventory/hosts.yml playbook.yml --limit k3s_agents

# Target only Raspberry Pi agents
ansible-playbook -i inventory/hosts.yml playbook.yml --limit pi_k3s_agents

# Target only RHEL agents
ansible-playbook -i inventory/hosts.yml playbook.yml --limit rhel_k3s_agents

# Target all Raspberry Pi devices (control plane + agents)
ansible-playbook -i inventory/hosts.yml playbook.yml --limit all_raspberry_pi

# Target the entire K3s cluster
ansible-playbook -i inventory/hosts.yml playbook.yml --limit k3s_cluster

# Target VPS servers
ansible-playbook -i inventory/hosts.yml playbook.yml --limit vps_servers
```

### Targeting Specific Hosts

```bash
# Target a single host
ansible-playbook -i inventory/hosts.yml playbook.yml --limit super6c_node_1

# Target multiple hosts
ansible-playbook -i inventory/hosts.yml playbook.yml --limit super6c_node_1,super6c_node_2

# Target hosts using patterns
ansible-playbook -i inventory/hosts.yml playbook.yml --limit 'super6c_node_*'
```

### Testing Connectivity

```bash
# Ping all hosts
ansible -i inventory/hosts.yml all -m ping

# Ping specific group
ansible -i inventory/hosts.yml k3s_agents -m ping

# Ping all Raspberry Pi devices
ansible -i inventory/hosts.yml all_raspberry_pi -m ping
```

## Group Variables

Group variables are stored in `group_vars/` and are automatically applied to hosts in those groups.

### Variable Precedence

Ansible applies variables in the following order (lowest to highest precedence):

1. `group_vars/all.yml` (if it exists)
2. `group_vars/all_raspberry_pi.yml` (for Pi devices)
3. `group_vars/k3s_cluster.yml` (if it exists)
4. `group_vars/k3s_control_plane.yml` or `group_vars/k3s_agents.yml`
5. `group_vars/pi_k3s_agents.yml`, `group_vars/rhel_k3s_agents.yml`, or `group_vars/vps_servers.yml`
6. Host-specific variables (inline in hosts.yml or in host_vars/)

### Common Variables

Each group_vars file typically sets:

- `ansible_user`: SSH username for the group
- `ansible_python_interpreter`: Python interpreter path (if needed)
- `ansible_become`: Whether to use privilege escalation (sudo)
- `ansible_become_method`: How to escalate privileges

## Adding New Hosts

### Adding a New Raspberry Pi Worker Node

1. Edit `hosts.yml` and add the host under `pi_k3s_agents`:
   ```yaml
   pi_k3s_agents:
     hosts:
       super6c_node_7:
         ansible_host: 172.16.10.XXX
   ```

2. The host will automatically inherit `ansible_user: root` from `group_vars/pi_k3s_agents.yml`

3. Test connectivity:
   ```bash
   ansible -i inventory/hosts.yml super6c_node_7 -m ping
   ```

### Adding a New RHEL Worker Node

1. Edit `hosts.yml` and add the host under `rhel_k3s_agents`:
   ```yaml
   rhel_k3s_agents:
     hosts:
       rhel_node_3:
         ansible_host: 172.16.10.XXX
   ```

2. The host will automatically inherit `ansible_user: kmulliken` from `group_vars/rhel_k3s_agents.yml`

### Adding a New VPS Server

1. Edit `hosts.yml` and add the host under `vps_servers`:
   ```yaml
   vps_servers:
     hosts:
       rack_nerd_2:
         ansible_host: XX.XX.XX.XX
   ```

2. The host will automatically inherit `ansible_user: root` from `group_vars/vps_servers.yml`

## Inventory Verification

### Viewing Inventory Structure

```bash
# List all hosts
ansible-inventory -i inventory/hosts.yml --list

# View inventory as a graph
ansible-inventory -i inventory/hosts.yml --graph

# View specific group
ansible-inventory -i inventory/hosts.yml --graph k3s_agents

# View host variables
ansible-inventory -i inventory/hosts.yml --host super6c_node_1
```

### Verifying Group Membership

```bash
# List hosts in a group
ansible -i inventory/hosts.yml k3s_agents --list-hosts

# List hosts in all_raspberry_pi
ansible -i inventory/hosts.yml all_raspberry_pi --list-hosts
```

## SSH Configuration

Ensure your SSH keys are properly configured for each host:

```bash
# Test SSH access manually
ssh kglitchy@172.16.10.246  # super6c_node_1 (control plane)
ssh root@172.16.10.40       # super6c_node_2 (Pi agent)
ssh kmulliken@100.112.141.30 # rhel_node_1 (RHEL agent)
```

If you need to use SSH keys, add them to your group_vars or host_vars:

```yaml
ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

## Troubleshooting

### Connection Issues

If you can't connect to a host:

1. Verify the IP address is correct:
   ```bash
   ping 172.16.10.246
   ```

2. Verify SSH access works:
   ```bash
   ssh kglitchy@172.16.10.246
   ```

3. Check Ansible can connect:
   ```bash
   ansible -i inventory/hosts.yml super6c_node_1 -m ping -vvv
   ```

### Permission Issues

If you get permission denied errors:

1. Verify the username in group_vars is correct
2. Check if the user needs sudo privileges
3. Add to group_vars if needed:
   ```yaml
   ansible_become: yes
   ansible_become_method: sudo
   ```

### Python Interpreter Issues

If Ansible can't find Python on the remote host:

1. Check which Python is installed:
   ```bash
   ansible -i inventory/hosts.yml <host> -m shell -a "which python3"
   ```

2. Set the correct interpreter in group_vars:
   ```yaml
   ansible_python_interpreter: /usr/bin/python3
   ```

## Best Practices

1. **Keep sensitive data out of the inventory**: Use Ansible Vault for passwords and secrets
2. **Use group_vars instead of inline variables**: Easier to maintain and override
3. **Document changes**: Update this README when adding new groups or hosts
4. **Test changes**: Always run with `--check` mode first
5. **Use meaningful host names**: Follow the existing naming convention
6. **Keep backups**: Version control this directory with Git

## Related Documentation

- Main project documentation: `../CLAUDE.md`
- Playbook documentation: `../playbooks/README.md` (if it exists)
- Role documentation: `../roles/<role-name>/README.md`

## Changelog

- **2024**: Reorganized inventory structure
  - Split control plane from agents (only super6c_node_1 is control plane)
  - Created platform-specific groups (all_raspberry_pi)
  - Moved from `raspberrypi`/`servers` groups to functional groups
  - Created comprehensive group_vars for each group
  - Removed redundant inline `ansible_user` declarations