# Raspberry Pi & Kubernetes Infra Automation (Ansible)

Automate the lifecycle of Raspberry Pi clusters and Kubernetes app deployments. Ansible handles provisioning, configuration, application rollout (Docmost, Ghost), and secret management (Kubeseal). The structure is modular and easy to extend.

---

## Project Layout

```text
roles/           # Modular Ansible roles (Pi setup, K8s apps, etc.)
playbooks/       # Main workflows (site bootstrap, reboots, etc.)
inventory/       # Raspberry Pi host definitions
requirements.txt # Python dependencies for Ansible/Molecule
galaxy.yml       # Collection metadata (optional, for Galaxy packaging)
README.md        # You're reading it
```

---

## Quick-Start

### 1. Prerequisites

- Ansible (install with `pip install -r requirements.txt`)
- SSH access to your Pis
- A valid kubeconfig with admin rights to your cluster
- Kubeseal installed (for encrypted secrets)
- Cloudflare API token (optional – only if you want DNS automation)

### 2. Inventory Setup

Edit `inventory/raspberrypi.yml`:

```yaml
all:
  children:
    raspberrypi:
      hosts:
        pi1:
          ansible_host: 192.168.1.10
        pi2:
          ansible_host: 192.168.1.11
      vars:
        ansible_user: youruser
```

### 3. Configure Variables

- `roles/k8s/defaults/main.yml` – cluster & app parameters
- Secret management: All plaintext secrets must be sealed with Kubeseal before deployment.

### 4. Encrypt & Place Secrets

```sh
kubeseal --format yaml < my-secrets.yaml > sealedsecrets.yaml
```

Place the output in `roles/k8s/files/<app>/sealedsecrets.yaml`.

---

## Usage

### Deploy Everything

```sh
ansible-playbook playbooks/site.yml -i inventory/raspberrypi.yml -K
# -K prompts for sudo/SSH password if required
```

### Reboot Devices

```sh
ansible-playbook playbooks/reboot.yml -i inventory/raspberrypi.yml -K
```

---

## Roles / Playbooks at a Glance

| Role / Playbook | Purpose                                                        |
|-----------------|----------------------------------------------------------------|
| rpi_setup       | Installs & configures iSCSI, sets cgroup options, enables services |
| k8s             | Deploys K8s Dashboard, Docmost, Ghost, Kubeseal                |
| reboot          | Utility role that reboots Pis                                  |
| dns_cname       | (optional) Creates Cloudflare CNAMEs via API                   |
| lix, nix_darwin | (optional) Local Nix tooling/bootstrap                         |

---

## App Deployments

| App           | Stack Components                                 | Notes                |
|---------------|--------------------------------------------------|----------------------|
| Docmost       | StatefulSet, Postgres, Redis, Cloudflared tunnel | Knowledge-base       |
| Ghost         | StatefulSet, MySQL, Cloudflared, sealed secrets  | Blogging CMS         |
| K8s Dashboard | Web UI exposed via NodePort or LB                | Admin token auto-created |

All manifests live in `roles/k8s/files/<app>/`.  
Update domain names and secret values for your environment.

---

## Security Checklist

- Never commit plaintext secrets – always use Kubeseal.
- Replace placeholder domains (`*.mulliken.net`) with your own.
- Use SSH keys wherever possible (password auth only as fallback).

---

## Extending the Stack

1. Add a new role under `roles/` and reference it in the relevant playbook.
2. Use variables and templates for environment-specific tweaks.
3. (Optional) Add Molecule tests for CI-ready validation.

---

## License

GPL-2.0-or-later – see `galaxy.yml` for full details.

---

Built for pragmatic, security-minded automation of ARM clusters and K8s workloads. PRs to improve, modernize, or harden are welcome.
