# configure_traefik_acme

Configures Traefik with Let's Encrypt ACME via Cloudflare DNS challenge for automatic TLS certificates.

## Requirements

- K3s with Traefik installed
- Cloudflare account with API token
- Domain managed by Cloudflare DNS

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `traefik_acme_email` | `katie@mulliken.net` | ACME account email |
| `traefik_acme_domain` | `*.corp.mulliken.net` | Wildcard domain for certificates |

## Setup

Before deploying, create the Cloudflare API token sealed secret:

```bash
# 1. Create raw secret
cat > /tmp/cloudflare-secrets.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: kube-system
type: Opaque
stringData:
  CF_DNS_API_TOKEN: your-cloudflare-api-token
EOF

# 2. Seal the secret
kubeseal --format=yaml < /tmp/cloudflare-secrets.yaml > roles/configure_traefik_acme/files/sealedsecrets.yaml

# 3. Clean up
rm /tmp/cloudflare-secrets.yaml
```

## Usage

```yaml
- hosts: localhost
  roles:
    - configure_traefik_acme
```

## Using Certificates

In your IngressRoutes, add:

```yaml
spec:
  tls:
    certResolver: cloudflare
    domains:
      - main: corp.mulliken.net
        sans:
          - "*.corp.mulliken.net"
```

## Dependencies

None
