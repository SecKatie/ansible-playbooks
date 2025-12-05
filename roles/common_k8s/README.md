# common_k8s - Common Kubernetes Resource Library

A library role providing reusable task files for creating common Kubernetes resources across all application roles.

## Purpose

This role eliminates duplication by providing standardized task files for:
- Namespaces
- cert-manager Certificates
- Standard Kubernetes Ingress
- Traefik IngressRoute (for HTTPS backends)
- Cloudflare tunnel deployments
- Storage (PVC)

## Usage

This is a library role - it's not meant to be called directly. Instead, include specific task files from your roles:

```yaml
- name: Create namespace
  include_role:
    name: common_k8s
    tasks_from: namespace
  vars:
    k8s_namespace: my-app
    k8s_labels:
      app.kubernetes.io/name: my-app
      app.kubernetes.io/part-of: applications
```

## Available Task Files

### namespace.yml

Creates a Kubernetes namespace with standard labels.

**Required variables:**
- `k8s_namespace`: Namespace name (string, non-empty)

**Optional variables:**
- `k8s_labels`: Additional labels (dict)

**Validation:**
- Checks that `k8s_namespace` is defined, non-empty, and a string
- Checks that `k8s_labels` is a dictionary if provided

**Example:**
```yaml
- include_role:
    name: common_k8s
    tasks_from: namespace
  vars:
    k8s_namespace: jellyfin
    k8s_labels:
      app.kubernetes.io/name: jellyfin
      app.kubernetes.io/part-of: media
```

### certificate.yml

Creates a cert-manager Certificate for Let's Encrypt TLS.

**Required variables:**
- `k8s_namespace`: Namespace for the certificate (string, non-empty)
- `k8s_cert_name`: Name of the Certificate resource (string, non-empty)
- `k8s_cert_secret_name`: Name of the TLS secret to create (string, non-empty)
- `k8s_cert_dns_names`: List of DNS names for the certificate (list, non-empty)

**Optional variables:**
- `k8s_cert_issuer`: ClusterIssuer name (default: `letsencrypt-prod`, string)
- `k8s_labels`: Additional labels (dict)

**Validation:**
- All required variables must be defined and non-empty
- `k8s_cert_dns_names` must be a list with at least one entry
- `k8s_cert_issuer` must be a string if provided

**Example:**
```yaml
- include_role:
    name: common_k8s
    tasks_from: certificate
  vars:
    k8s_namespace: jellyfin
    k8s_cert_name: jellyfin-tls
    k8s_cert_secret_name: jellyfin-tls
    k8s_cert_dns_names:
      - jellyfin.corp.mulliken.net
    k8s_labels:
      app.kubernetes.io/name: jellyfin
```

### ingress.yml

Creates a standard Kubernetes Ingress with TLS.

**Required variables:**
- `k8s_namespace`: Namespace for the ingress (string, non-empty)
- `k8s_ingress_name`: Name of the Ingress resource (string, non-empty)
- `k8s_ingress_host`: Hostname for the ingress (string, non-empty)
- `k8s_ingress_service_name`: Backend service name (string, non-empty)
- `k8s_ingress_service_port`: Backend service port (number or string)
- `k8s_ingress_tls_secret`: TLS secret name (string, non-empty)

**Optional variables:**
- `k8s_ingress_class`: Ingress class (default: `traefik`, string)
- `k8s_ingress_path`: Path for routing (default: `/`, string)
- `k8s_ingress_path_type`: Path type (default: `Prefix`, must be one of: `Prefix`, `Exact`, `ImplementationSpecific`)
- `k8s_labels`: Additional labels (dict)

**Validation:**
- All required variables must be defined and non-empty
- `k8s_ingress_path_type` must be a valid Kubernetes path type if provided

**Example:**
```yaml
- include_role:
    name: common_k8s
    tasks_from: ingress
  vars:
    k8s_namespace: jellyfin
    k8s_ingress_name: jellyfin
    k8s_ingress_host: jellyfin.corp.mulliken.net
    k8s_ingress_service_name: jellyfin
    k8s_ingress_service_port: 8096
    k8s_ingress_tls_secret: jellyfin-tls
    k8s_labels:
      app.kubernetes.io/name: jellyfin
```

### ingressroute.yml

Creates a Traefik IngressRoute with ServersTransport (for HTTPS backends with self-signed certs).

**Required variables:**
- `k8s_namespace`: Namespace for the IngressRoute (string, non-empty)
- `k8s_ingressroute_name`: Name of the IngressRoute resource (string, non-empty)
- `k8s_ingressroute_host`: Hostname for routing (string, non-empty)
- `k8s_ingressroute_service_name`: Backend service name (string, non-empty)
- `k8s_ingressroute_service_port`: Backend service port (number or string)

**Optional variables:**
- `k8s_ingressroute_tls_secret`: TLS secret name (default: `wildcard-corp-tls`, string)
- `k8s_ingressroute_transport_name`: ServersTransport name (auto-generated if not provided, string)
- `k8s_ingressroute_insecure_skip_verify`: Skip TLS verification (default: `true`, boolean)
- `k8s_labels`: Additional labels (dict)

**Validation:**
- All required variables must be defined and non-empty
- `k8s_ingressroute_insecure_skip_verify` must be a boolean if provided

**Example:**
```yaml
- include_role:
    name: common_k8s
    tasks_from: ingressroute
  vars:
    k8s_namespace: kubernetes-dashboard
    k8s_ingressroute_name: kubernetes-dashboard
    k8s_ingressroute_host: dashboard.corp.mulliken.net
    k8s_ingressroute_service_name: kubernetes-dashboard-kong-proxy
    k8s_ingressroute_service_port: 443
    k8s_labels:
      app.kubernetes.io/name: kubernetes-dashboard
```

### cloudflare.yml

Creates a Cloudflare tunnel deployment with ConfigMap for external access.

**Required variables:**
- `k8s_namespace`: Namespace for cloudflared (string, non-empty)
- `k8s_cloudflare_tunnel_name`: Tunnel name (string, non-empty)
- `k8s_cloudflare_external_hostname`: External hostname (string, non-empty, e.g., `jellyfin.mulliken.net`)
- `k8s_cloudflare_internal_service`: Internal service URL (string, must start with `http://` or `https://`, e.g., `http://jellyfin.jellyfin.svc.cluster.local:8096`)
- `k8s_cloudflare_secret_name`: Name of the secret containing tunnel credentials (string, non-empty)

**Optional variables:**
- `k8s_cloudflare_deployment_name`: Deployment name (default: `cloudflared`, string)
- `k8s_cloudflare_replicas`: Number of replicas (default: `1`, number > 0)
- `k8s_cloudflare_image`: Cloudflared image (default: `cloudflare/cloudflared:2025.11.1`, string)
- `k8s_labels`: Additional labels (dict)

**Validation:**
- All required variables must be defined and non-empty
- `k8s_cloudflare_internal_service` must start with `http://` or `https://`
- `k8s_cloudflare_replicas` must be a positive number if provided

**Example:**
```yaml
- include_role:
    name: common_k8s
    tasks_from: cloudflare
  vars:
    k8s_namespace: jellyfin
    k8s_cloudflare_tunnel_name: jellyfin-tunnel
    k8s_cloudflare_external_hostname: jellyfin.mulliken.net
    k8s_cloudflare_internal_service: http://jellyfin.jellyfin.svc.cluster.local:8096
    k8s_cloudflare_secret_name: cloudflare-tunnel-creds
    k8s_labels:
      app.kubernetes.io/name: jellyfin
```

### storage.yml

Creates a PersistentVolumeClaim for application storage.

**Required variables:**
- `k8s_namespace`: Namespace for the PVC (string, non-empty)
- `k8s_pvc_name`: PVC name (string, non-empty)
- `k8s_pvc_size`: Storage size (string, format: `<number><Ki|Mi|Gi|Ti|Pi>`, e.g., `10Gi`)

**Optional variables:**
- `k8s_pvc_storage_class`: Storage class (default: `longhorn`, string)
- `k8s_pvc_access_mode`: Access mode (default: `ReadWriteOnce`, must be one of: `ReadWriteOnce`, `ReadOnlyMany`, `ReadWriteMany`, `ReadWriteOncePod`)
- `k8s_labels`: Additional labels (dict)

**Validation:**
- All required variables must be defined and non-empty
- `k8s_pvc_size` must match format: `<number><Ki|Mi|Gi|Ti|Pi>` (e.g., `10Gi`, `500Mi`)
- `k8s_pvc_access_mode` must be a valid Kubernetes access mode if provided

**Example:**
```yaml
- include_role:
    name: common_k8s
    tasks_from: storage
  vars:
    k8s_namespace: jellyfin
    k8s_pvc_name: jellyfin-config-pvc
    k8s_pvc_size: 10Gi
    k8s_labels:
      app.kubernetes.io/name: jellyfin
```

## Benefits

- **Consistency**: All resources follow the same structure and labeling conventions
- **DRY**: No code duplication across 15+ application roles
- **Maintainability**: Fix bugs or add features in one place
- **Simplicity**: New roles become much simpler to write
- **Validation**: All task files validate required variables with helpful error messages

## Variable Validation

All task files include comprehensive validation that checks:

- **Required variables are defined**: Fails with clear error messages if variables are missing
- **Correct types**: Ensures strings are strings, lists are lists, etc.
- **Valid formats**: Validates storage sizes (e.g., `10Gi`), URLs (e.g., `http://...`), path types, etc.
- **Helpful error messages**: Shows which variables are missing or invalid

### Example Error Message

When validation fails, you'll see a clear error message:

```
TASK [Validate required variables for ingress] *********************************
fatal: [localhost]: FAILED! => {
    "assertion": false,
    "changed": false,
    "evaluated_to": false,
    "msg": "Variable validation failed for ingress creation:\n- k8s_namespace: jellyfin\n- k8s_ingress_name: jellyfin\n- k8s_ingress_host: NOT DEFINED\n- k8s_ingress_service_name: jellyfin\n- k8s_ingress_service_port: 8096\n- k8s_ingress_tls_secret: jellyfin-tls\n\nRequired: All variables above must be defined\nOptional: k8s_ingress_class, k8s_ingress_path, k8s_ingress_path_type (Prefix/Exact/ImplementationSpecific), k8s_labels"
}
```

This catches configuration errors early, before attempting to create resources in Kubernetes.

### Example Success Message

When validation passes:

```
TASK [Validate required variables for ingress] *********************************
ok: [localhost] => {
    "changed": false,
    "msg": "Validation passed for ingress: jellyfin"
}
```

## Migration Guide

To migrate an existing role to use `common_k8s`:

**Before:**
```yaml
- name: Apply certificate
  kubernetes.core.k8s:
    state: present
    definition: "{{ lookup('template', 'certificate.yaml.j2') }}"
```

**After:**
```yaml
- name: Create certificate
  include_role:
    name: common_k8s
    tasks_from: certificate
  vars:
    k8s_namespace: "{{ myapp_namespace }}"
    k8s_cert_name: "{{ myapp_cert_name }}"
    k8s_cert_secret_name: "{{ myapp_tls_secret }}"
    k8s_cert_dns_names:
      - "{{ myapp_ingress_host }}"
```

Then delete the `templates/certificate.yaml.j2` file from your role.

