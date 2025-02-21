# Ansible Playbooks for Infrastructure and Application Deployment

This repository contains Ansible playbooks and roles to automate the configuration and deployment of various services and applications. It provides a structured approach to manage infrastructure as code, ensuring consistency and repeatability across different environments.

## Structure

The repository is organized into the following key components:

*   **`site.yml`**: The main playbook that orchestrates the execution of different roles on different hosts.
*   **`dns.yml`**: Playbook specifically for configuring DNS settings, particularly for Cloudflare.
*   **`webui.yml`**: Playbook for deploying OpenWebUI and configuring the hosts file.
*   **`reboot.yml`**: Playbook to reboot Raspberry Pi devices.
*   **`roles/`**:  A directory containing reusable Ansible roles, each responsible for configuring a specific service or application.
*   **`apps/`**: Contains Kubernetes manifests for different applications, managed using `kustomize`.

## Playbooks

### `site.yml`

This is the primary entry point for running the Ansible configuration. It defines the target hosts and the roles to be applied to each.

```yaml
---
- name: Setup nix environment
  hosts: localhost
  gather_facts: false
  roles:
    - lix
    - nix_darwin

- name: Setup rpi_cgroup
  hosts: raspberrypi
  gather_facts: false
  roles:
    - rpi_cgroup

- name: Setup k8s_dashboard
  hosts: localhost
  gather_facts: false
  roles:
    - k8s_dashboard

- name: Setup rpi_iscsi
  hosts: raspberrypi
  gather_facts: false
  roles:
    - rpi_iscsi

- name: Deploy Docmost
  hosts: localhost
  gather_facts: true
  roles:
    - deploy_docmost
```

This playbook performs the following actions:

1.  **Nix Environment Setup**: Configures the Nix package manager environment on `localhost`.
2.  **Raspberry Pi Cgroup Setup**: Configures cgroup settings on Raspberry Pi devices.
3.  **Kubernetes Dashboard Setup**: Deploys and configures a Kubernetes dashboard on `localhost`.
4.  **Raspberry Pi iSCSI Setup**: Configures iSCSI initiator on Raspberry Pi devices.
5.  **Docmost Deployment**: Deploys the Docmost application to a Kubernetes cluster using `kustomize`.

### `dns.yml`

This playbook is responsible for managing DNS records using Cloudflare's API.

```yaml
---
- name: Configure DNS settings
  hosts: localhost
  gather_facts: false

  vars_prompt:
    - name: prompt_token
      prompt: "Enter your Cloudflare API token"
      private: true
      default: ""

  roles:
    - dns_cname
```

It prompts for a Cloudflare API token (if not already set as an environment variable) and then applies the `dns_cname` role.

### `webui.yml`

This playbook deploys OpenWebUI to a Kubernetes cluster and configures a hosts entry.

```yaml
---
- name: Deploy OpenWebUI and configure hosts entry
  hosts: localhost
  gather_facts: true
  vars:
    k8s_openwebui_hostname: "webui.local"
    hosts_entry_ip: "172.16.10.150"
    hosts_entry_hostnames:
      - "{{ k8s_openwebui_hostname }}"

  roles:
    - k8s_openwebui
    - hosts_entry
```

It defines variables for the hostname and IP address and then applies the `k8s_openwebui` and `hosts_entry` roles.

### `reboot.yml`

This playbook reboots Raspberry Pi devices.

```yaml
---
- name: Reboot Raspberry Pi devices
  hosts: raspberrypi
  roles:
    - reboot
```

It applies the `reboot` role to all hosts in the `raspberrypi` group.

## Roles

### `lix`

Installs the Lix package manager, which enhances Nix package management experience.

*   **Tasks**: Downloads and executes the Lix installation script.

### `nix_darwin`

Configures Nix on macOS using `nix-darwin`.

*   **Tasks**: Runs the `nix-darwin switch` command to apply the configuration defined in `~/.config/nix-darwin`.

### `rpi_cgroup`

Enables cgroup memory management on Raspberry Pi devices.

*   **Tasks**: Modifies `/boot/firmware/cmdline.txt` to include `cgroup_memory=1 cgroup_enable=memory`.

### `k8s_dashboard`

Deploys and configures the Kubernetes Dashboard.

*   **Tasks**:
    *   Creates a `kubernetes-dashboard` namespace.
    *   Downloads the recommended Kubernetes Dashboard manifest.
    *   Deploys the Dashboard.
    *   Updates the service type (NodePort or LoadBalancer).
    *   Creates an admin user with cluster-admin privileges.
    *   Retrieves the admin token for accessing the dashboard.
*   **Variables**:
    *   `k8s_dashboard_version`: Version of the Kubernetes Dashboard to deploy (default: `v2.7.0`).
    *   `k8s_dashboard_namespace`: Namespace where the Dashboard will be deployed (default: `kubernetes-dashboard`).
    *   `k8s_dashboard_service_type`: Service type for accessing the Dashboard (default: `NodePort`).  Can be set to `LoadBalancer`.
    *   `k8s_dashboard_node_port`:  NodePort value if `k8s_dashboard_service_type` is set to `NodePort` (default: `30443`).

### `rpi_iscsi`

Configures an iSCSI initiator on Raspberry Pi devices.

*   **Tasks**:
    *   Installs the `open-iscsi` package.
    *   Enables and starts the `iscsid` and `iscsi` services.
    *   Configures `/etc/iscsi/iscsid.conf` to enable automatic startup and set timeout values.
*   **Handlers**: Restarts the `iscsid` and `iscsi` services.

### `dns_cname`

Creates a CNAME record in Cloudflare DNS.

*   **Tasks**: Uses the `community.general.cloudflare_dns` module to create or update a CNAME record.
*   **Variables**:
    *   `dns_cname_zone`: The Cloudflare zone (domain name) where the record will be created (default: `mulliken.net`).
    *   `dns_cname_record`: The name of the CNAME record (default: `links`).
    *   `dns_cname_target`: The target of the CNAME record (default: `my-link-blog.fly.dev`).
    *   `dns_cname_cloudflare_api_token`:  The Cloudflare API token.  It first checks for an environment variable `CLOUDFLARE_API_TOKEN`. If not found, it prompts the user for the token.

### `deploy_docmost`

Deploys the Docmost application to a Kubernetes cluster using `kustomize`.

*   **Tasks**:
    *   Deploys Docmost using the `kubernetes.core.k8s` module and the `kustomize` lookup.
*   **Variables**:
    *   `kubeconfig_path`: Path to the kubeconfig file (default: `{{ ansible_env.HOME }}/.kube/config`).
    *   `k8s_context`: Kubernetes context to use (optional, default: "").
    *   `docmost_base_dir`: Base directory where Docmost kustomize files are located (default: `{{ playbook_dir }}`).
    *   `docmost_kustomize_path`: Path to the kustomize directory for Docmost relative to `base_dir` (default: `"apps/docmost"`).

### `k8s_openwebui`

This role is a placeholder and currently doesn't contain any tasks related to deploying OpenWebUI.  It would need to be implemented with the actual deployment logic.

### `hosts_entry`

Adds or updates entries in the `/etc/hosts` file.

*   **Tasks**:
    *   Backs up the existing `/etc/hosts` file (if `hosts_entry_backup` is true).
    *   Adds or updates entries for the specified hostnames and IP address.
*   **Variables**:
    *   `hosts_entry_ip`: IP address to use for the hosts entries (default: `127.0.0.1`).
    *   `hosts_entry_hostnames`: List of hostnames to add to `/etc/hosts` (default: `[]`).
    *   `hosts_entry_backup`: Whether to backup the hosts file before modifying (default: `true`).
    *   `hosts_entry_state`: State of the hosts entries (default: `"present"`).  Can also be set to `"absent"`.

### `reboot`

Reboots the target machine.

*   **Tasks**:
    *   Reboots the Raspberry Pi using the `ansible.builtin.reboot` module.

## Application Deployments (apps/)

The `apps/` directory contains Kubernetes manifests and `kustomization.yaml` files for deploying various applications. `kustomize` is used to manage these deployments.  Examples include Docmost and Ghost.

### Docmost

The `apps/docmost` directory contains the following files:

*   `kustomization.yaml`: Defines the resources to be deployed.
*   `namespace.yaml`: Creates the `docmost` namespace.
*   `secrets.yaml`: Defines secrets for the application (database password, etc.).
*   `configmap.yaml`: Defines configuration parameters for the application.
*   `storage.yaml`: Defines persistent volume claims for storage.
*   `postgres.yaml`: Defines the PostgreSQL database deployment.
*   `redis.yaml`: Defines the Redis deployment.
*   `docmost.yaml`: Defines the Docmost application deployment.
*   `cloudflared.yaml`: Defines a Cloudflare Tunnel deployment for exposing the application.
*   `docker-compose.yml`: A docker-compose file containing the deployment. Note that this is not used by the ansible scripts.

### Ghost

The `apps/ghost` directory contains the following files:

*   `kustomization.yaml`: Defines the resources to be deployed.
*   `namespace.yaml`: Creates the `ghost` namespace.
*   `statefulset.yaml`: Defines the Ghost application deployment as a StatefulSet.
*   `service.yaml`: Defines the Ghost service.
*   `mysql-statefulset.yaml`: Defines the MySQL database deployment as a StatefulSet.
*   `mysql-service.yaml`: Defines the MySQL service.
*   `mysql-secret.yaml`: Defines the MySQL root password as a secret.
*   `cloudflared.yaml`: Defines a Cloudflare Tunnel deployment for exposing the application.

## Requirements

*   Ansible (version X.X or higher)
*   Python 3.x
*   `community.general` Ansible collection: `ansible-galaxy collection install community.general`
*   `kubernetes.core` Ansible collection: `ansible-galaxy collection install kubernetes.core`
*   kubectl configured with access to your Kubernetes cluster (required for `deploy_docmost` and `k8s_dashboard` roles)
*   A Cloudflare account and API token (required for the `dns_cname` role)

## Usage

1.  **Clone the repository:**

    ```bash
    git clone <repository_url>
    cd <repository_directory>
    ```

2.  **Install dependencies:**

    ```bash
    ansible-galaxy collection install community.general kubernetes.core
    ```

3.  **Configure your inventory file:**

    Create or modify your Ansible inventory file to define the target hosts.  For example:

    ```ini
    [localhost]
    127.0.0.1 ansible_connection=local

    [raspberrypi]
    <raspberry_pi_ip_address> ansible_user=<username> ansible_ssh_private_key_file=~/.ssh/id_rsa
    ```

4.  **Run the main playbook:**

    ```bash
    ansible-playbook site.yml
    ```

    Or, to run a specific playbook:

    ```bash
    ansible-playbook dns.yml
    ```

5.  **For `dns.yml`, ensure the `CLOUDFLARE_API_TOKEN` environment variable is set or be prepared to enter it when prompted.**

## Contributing

Contributions are welcome! Please submit pull requests with clear descriptions of the changes.

## License

MIT