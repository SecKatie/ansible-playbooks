# setup_cloudflare_tunnel

Shared role for setting up Cloudflare tunnels. This role is designed to be included by other roles that need Cloudflare tunnel functionality.

## Requirements

- `cloudflared` CLI installed and authenticated
- Kubernetes cluster with kubectl configured

## Role Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `cf_tunnel_name` | Yes | Name of the Cloudflare tunnel |
| `cf_tunnel_namespace` | Yes | Kubernetes namespace for the secret |
| `cf_tunnel_secret_name` | Yes | Name of the Kubernetes secret for credentials |
| `cf_tunnel_enabled` | No | Set to `false` to skip tunnel setup (default: `true`) |

## Output Variables

After execution, these variables are set:

| Variable | Description |
|----------|-------------|
| `cf_tunnel_id` | The tunnel UUID |
| `cf_tunnel_creds_path` | Path to the credentials JSON file |
| `cf_tunnel_status` | Either `"existing"` or `"created"` |
| `cf_tunnel_configured` | `true` if tunnel was successfully configured |

## Usage

Include this role from another role:

```yaml
- name: Setup Cloudflare tunnel
  ansible.builtin.include_role:
    name: setup_cloudflare_tunnel
  vars:
    cf_tunnel_name: my-app-tunnel
    cf_tunnel_namespace: my-app
    cf_tunnel_secret_name: my-app-tunnel-credentials

- name: Deploy Cloudflare tunnel manifest
  kubernetes.core.k8s:
    state: present
    src: "{{ role_path }}/files/cloudflared.yaml"
  when: cf_tunnel_configured | default(false)
```

## Behavior

1. Checks if tunnel already exists
2. Creates tunnel if it doesn't exist
3. Creates Kubernetes secret with tunnel credentials
4. Sets output variables for use by calling role

## Dependencies

None
