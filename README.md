# Ansible Playbooks for Raspberry Pi and Kubernetes Management

This project uses Ansible to automate the setup and configuration of Raspberry Pi devices and to deploy applications on a Kubernetes cluster. It includes roles for basic Raspberry Pi setup, Kubernetes deployment (including the Kubernetes Dashboard, Docmost, Ghost), DNS CNAME record creation with Cloudflare, and a reboot utility. It also includes the Lix and nix-darwin installers for local configuration.

## Project Structure

The project is organized into several directories:

* `roles/`: Contains Ansible roles for specific tasks.
* `playbooks/`: Contains Ansible playbooks that define the overall configuration workflow.
* `inventory/`: Holds the inventory file that defines the target hosts.

### Roles

Each role encapsulates a set of tasks, variables, and handlers to achieve a specific configuration goal.

* **`reboot`**: Reboots the Raspberry Pi.
    * `tasks/main.yml`: Contains the task to reboot the Raspberry Pi using the `ansible.builtin.reboot` module.
* **`rpi_setup`**: Configures Raspberry Pi devices for Kubernetes.
    * `tasks/main.yml`: Imports the necessary tasks.
    * `tasks/install.yml`: Installs the `open-iscsi` package.
    * `tasks/services.yml`: Enables and starts the `iscsid` and `iscsi` services.
    * `tasks/configure.yml`: Configures `/etc/iscsi/iscsid.conf` with settings like `node.startup = automatic`. Includes a handler to restart the iscsi services after configuration changes.
    * `tasks/cmdline.yml`: Ensures that `cgroup_memory=1 cgroup_enable=memory` is present in `/boot/firmware/cmdline.txt`. This is important for Kubernetes to function properly.
* **`k8s`**: Deploys applications to a Kubernetes cluster.
    * `tasks/main.yml`: Imports the necessary tasks.
    * `tasks/dashboard.yml`: Deploys the Kubernetes Dashboard. It also updates the service type for accessing the dashboard, creates an admin user, and displays access information.
    * `tasks/docmost.yml`: Deploys Docmost, an open-source knowledge base, to the Kubernetes cluster. Uses a `with_fileglob` loop to deploy all YAML files in the `docmost/` directory.
    * `tasks/ghost.yml`: Deploys Ghost, a blogging platform, to the Kubernetes cluster. Uses a `with_fileglob` loop to deploy all YAML files in the `ghost/` directory.
    * `tasks/kubeseal.yml`: Deploys Kubeseal, a tool for encrypting Kubernetes secrets.
    * `defaults/main.yml`: Defines default values for variables used in the role, such as the Kubernetes Dashboard version, namespace, service type, node port, and manifest URLs.
    * `files/docmost/`: Contains YAML files for deploying Docmost, including definitions for the `cloudflared` tunnel, `ConfigMap`, `StatefulSet`, `Service`, `Namespace`, `Postgres`, `Redis`, and a `SealedSecret`. An example `secrets.example.yaml` file shows how to define sensitive information that should be sealed.
    * `files/ghost/`: Contains YAML files for deploying Ghost, including definitions for the `cloudflared` tunnel, `MySQL` database, and Ghost application. Uses a `SealedSecret` for MySQL password encryption.
    * `templates/dashboard-admin.yml.j2`: Template for creating an admin user for the Kubernetes Dashboard.
    * `templates/dashboard-service.yml.j2`: Template for updating the Kubernetes Dashboard service type.
* **`dns_cname`**: Creates a CNAME record in Cloudflare DNS.
    * `tasks/main.yml`: Creates a CNAME record using `community.general.cloudflare_dns`.
    * `defaults/main.yml`: Defines default values for the Cloudflare zone, record name, and target.
    * `vars/main.yml`: Defines a variable to retrieve the Cloudflare API token from an environment variable, falling back to a prompt if not set.
* **`lix`**: Installs the Lix package manager.
    * `tasks/main.yml`: Checks if nix is installed and installs it if it's not.
* **`nix_darwin`**: Runs the nix-darwin rebuild command.
    * `tasks/main.yml`: Checks if darwin-rebuild is installed and runs it if it's not.

### Playbooks

Playbooks define the order of execution for the roles.

* **`reboot.yml`**: Reboots the Raspberry Pi devices.
* **`site.yml`**: The main playbook that sets up the nix environment locally and configures the Kubernetes cluster via roles: `lix`, `nix_darwin`, and `k8s`. Includes commented-out sections to configure raspberry pi hosts and setup dns cname.

### Inventory

The inventory file defines the target hosts for the playbooks.

* **`inventory/raspberrypi.yml`**: Defines the Raspberry Pi hosts and their connection details.

## Usage

### Prerequisites

* Ansible installed on your control machine.
* A Kubernetes cluster is running and accessible from your control machine, or a valid kubeconfig file configured.
* Raspberry Pi devices with SSH access enabled.
* Cloudflare account and API token (for the `dns_cname` role).
* Lix installed on your control machine.

### Configuration

1. **Inventory Setup:**
    * Modify the `inventory/raspberrypi.yml` file to include the IP addresses or hostnames of your Raspberry Pi devices. Update the `ansible_user` variable with the correct username.
2. **Variable Configuration:**
    * For the `k8s` role, customize the variables in `roles/k8s/defaults/main.yml` to match your Kubernetes cluster configuration. Adjust the `k8s_dashboard_service_type` and `k8s_dashboard_node_port` according to your network setup.
    * For the `dns_cname` role, set the `dns_cname_zone`, `dns_cname_record`, and `dns_cname_target` variables in `roles/dns_cname/defaults/main.yml` to match your domain and target. Set the `CLOUDFLARE_API_TOKEN` environment variable or modify the `roles/dns_cname/vars/main.yml` file.
3. **Secret Management:**
    * For Docmost and Ghost deployments, create `SealedSecret` resources in `roles/k8s/files/docmost/sealedsecrets.yaml` and `roles/k8s/files/ghost/mysql-sealedsecret.yaml`. Use `kubeseal` to encrypt secrets and store the encrypted result in the sealed secret files. Use `secrets.example.yaml` in `roles/k8s/files/docmost/` as an example.
    * Alternatively, encrypt manually using `kubeseal --controller-namespace kube-system --format yaml < secrets.example.yaml > sealed-secrets.yaml`, where `kube-system` is the default namespace for the kubeseal controller.

### Execution

1. **Run the `site.yml` playbook:**

    ```bash
    ansible-playbook playbooks/site.yml -i inventory/raspberrypi.yml -K
    ```

    The `-K` option prompts for the SSH password for the Raspberry Pi devices.

2. **Run the `reboot.yml` playbook (optional):**

    ```bash
    ansible-playbook playbooks/reboot.yml -i inventory/raspberrypi.yml -K
    ```

### Molecule Testing

This project uses [Molecule](https://molecule.readthedocs.io/) for testing Ansible roles. Molecule provides a standardized way to test roles in isolation, ensuring they work as expected across different environments.

#### Setup for Testing

1. **Install dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

   Alternatively, use the provided script to set up a virtual environment and install dependencies:

   ```bash
   ./molecule-test.sh
   ```

2. **Run tests for a specific role:**

   ```bash
   cd roles/rpi_setup
   molecule test
   ```

   Or use the script:

   ```bash
   ./molecule-test.sh rpi_setup
   ```

3. **Run tests for all roles:**

   ```bash
   ./molecule-test.sh
   ```

#### Test Structure

Each role that has Molecule tests includes:

* `molecule/default/molecule.yml`: Main configuration file defining the test environment.
* `molecule/default/converge.yml`: Playbook that applies the role during testing.
* `molecule/default/verify.yml`: Playbook that runs tests to verify role functionality.

#### Adding Tests to a New Role

1. Initialize Molecule for a role:

   ```bash
   cd roles/your_role_name
   molecule init scenario --role-name your_role_name
   ```

2. Customize the verification tests in `verify.yml` to test specific aspects of your role.

#### Testing Workflow

Molecule tests follow this sequence:

1. **Lint**: Checks YAML files for syntax and formatting issues.
2. **Destroy**: Ensures a clean testing environment.
3. **Dependency**: Installs role dependencies.
4. **Syntax**: Validates playbook syntax.
5. **Create**: Sets up the test instance (Docker container).
6. **Prepare**: Prepares the instance for testing.
7. **Converge**: Applies the role to the test instance.
8. **Idempotence**: Verifies that the role can be run multiple times without changes.
9. **Verify**: Runs tests to check if the role worked as expected.
10. **Destroy**: Cleans up the test environment.

## Notes

* This project assumes that you have a basic understanding of Ansible, Kubernetes, and Raspberry Pi devices.
* Ensure that your control machine can SSH into the Raspberry Pi devices.
* Customize the roles and playbooks to match your specific requirements.
* The provided YAML files for Docmost and Ghost are examples and might require adjustments based on your environment.
* For enhanced security, consider using Ansible Vault to encrypt sensitive data.
* Kubeseal is used to manage Kubernetes secrets securely. Ensure that Kubeseal is properly configured in your cluster before deploying applications that rely on secrets.
* The cloudflared configurations are set up with placeholder domain names (`docmost.mulliken.net` and `blog.mulliken.net`). You will need to replace these with your actual domain names and configure Cloudflare DNS to point to your cluster's external IP or load balancer.
