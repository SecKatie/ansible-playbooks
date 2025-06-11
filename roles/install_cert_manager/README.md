# cert-manager Installation Role

This Ansible role installs [cert-manager](https://cert-manager.io/) on Kubernetes using the official kubectl installation method.

## Features

- **Latest Version**: Installs cert-manager v1.17.2 by default (configurable)
- **Idempotent**: Safe to run multiple times without changes
- **Verification**: Built-in verification of installation success
- **End-to-End Testing**: Optional test certificate creation and validation
- **Comprehensive Logging**: Detailed status and next-steps information

## Prerequisites

1. **Kubernetes cluster** with kubectl access
2. **Ansible** with `kubernetes.core` collection installed:
   ```bash
   ansible-galaxy collection install kubernetes.core
   ```
3. **kubectl** version >= v1.19.0
4. **Cluster admin permissions** for installing cluster-wide resources

## Installation

### Basic Installation

```yaml
- hosts: localhost
  roles:
    - install_cert_manager
```

### With Custom Configuration

```yaml
- hosts: localhost
  roles:
    - name: install_cert_manager
      vars:
        cert_manager_version: "v1.17.2"
        cert_manager_verify_installation: true
        cert_manager_e2e_test: true
```

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `cert_manager_version` | `v1.17.2` | Version of cert-manager to install |
| `cert_manager_manifest_url` | Auto-generated | URL to the cert-manager manifest |
| `cert_manager_manifest_dest` | `/tmp/cert-manager-{{ version }}.yaml` | Local path for downloaded manifest |
| `cert_manager_namespace` | `cert-manager` | Namespace where cert-manager is installed |
| `cert_manager_verify_installation` | `true` | Whether to verify the installation |
| `cert_manager_e2e_test` | `false` | Whether to run end-to-end test |
| `cert_manager_wait_timeout` | `300` | Timeout in seconds for pods to be ready |

## What Gets Installed

cert-manager consists of three main components:

1. **cert-manager controller**: Main certificate management logic
2. **cert-manager-cainjector**: Injects CA data into webhooks and APIServices
3. **cert-manager-webhook**: Validates and mutates cert-manager resources

All components are installed in the `cert-manager` namespace.

## Verification

The role includes multiple verification steps:

### Automatic Verification
- Waits for all pods to be in `Running` state
- Checks cert-manager API availability using `cmctl` (if available)
- Fallback verification by checking CRD availability

### Optional End-to-End Test
Set `cert_manager_e2e_test: true` to run a complete test that:
1. Creates a test namespace
2. Creates a self-signed issuer
3. Requests a test certificate
4. Verifies certificate is issued successfully
5. Cleans up test resources

## Usage Examples

### Basic Let's Encrypt ClusterIssuer

After installation, create a ClusterIssuer for Let's Encrypt:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

### Request a Certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com-tls
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - example.com
  - www.example.com
```

## Troubleshooting

### Check Installation Status
```bash
# Check pods
kubectl get pods -n cert-manager

# Check logs
kubectl logs -n cert-manager deployment/cert-manager
kubectl logs -n cert-manager deployment/cert-manager-webhook
kubectl logs -n cert-manager deployment/cert-manager-cainjector

# Verify API (requires cmctl)
cmctl check api
```

### Common Issues

1. **Pods not starting**: Check resource constraints and node capacity
2. **Webhook not ready**: Wait longer or check network policies
3. **Certificate requests failing**: Verify issuer configuration and DNS/HTTP challenges

### Manual Verification

If automatic verification fails, manually check:

```bash
# Check CRDs are installed
kubectl get crd | grep cert-manager

# Check all components are running
kubectl get all -n cert-manager

# Test certificate creation
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-cert
  namespace: default
spec:
  secretName: test-cert-tls
  issuerRef:
    name: test-issuer
    kind: Issuer
  dnsNames:
  - test.example.com
EOF
```

## Uninstalling

To uninstall cert-manager:

```bash
# Delete all cert-manager resources first
kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges --all-namespaces

# Then delete the installation
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml
```

## Security Notes

- cert-manager requires cluster-admin permissions during installation
- The webhook component needs to be trusted by the Kubernetes API server
- Consider network policies to restrict access to cert-manager components
- Private keys for certificates are stored as Kubernetes secrets

## References

- [Official cert-manager Documentation](https://cert-manager.io/docs/)
- [Installation Guide](https://cert-manager.io/docs/installation/kubectl/)
- [Configuration Options](https://cert-manager.io/docs/configuration/)
- [Troubleshooting Guide](https://cert-manager.io/docs/troubleshooting/)

## Support

For issues with cert-manager itself, see:
- [cert-manager GitHub Issues](https://github.com/cert-manager/cert-manager/issues)
- [cert-manager Community](https://cert-manager.io/docs/contributing/) 