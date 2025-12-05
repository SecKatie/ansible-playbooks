# Jellyfin Migration to common_k8s

## Summary

The Jellyfin role has been successfully migrated to use the `common_k8s` library role, eliminating template duplication and standardizing resource creation.

## What Changed

### Tasks (`tasks/main.yml`)
- **Namespace**: Now uses `common_k8s/namespace` task
- **Certificate**: Now uses `common_k8s/certificate` task
- **Ingress**: Now uses `common_k8s/ingress` task
- **Config PVC**: Now uses `common_k8s/storage` task
- **Cloudflare tunnel**: Now uses `common_k8s/cloudflare` task (plus `util_cloudflare_tunnel` for credential setup)

### Templates Removed
The following templates were deleted as they're now handled by `common_k8s`:
- `certificate.yaml.j2` → `common_k8s/certificate` task
- `ingress.yaml.j2` → `common_k8s/ingress` task
- `cloudflared.yaml.j2` → `common_k8s/cloudflare` task

### Templates Kept
- `jellyfin.yaml.j2` - Application-specific Deployment and Service
- `storage.yaml.j2` - NFS PersistentVolume and PVC (custom storage setup)

## Data Safety

**Your Jellyfin data is safe!** The migration preserves:

1. **Same PVC names**: 
   - `jellyfin-config-pvc` (for config/metadata)
   - `jellyfin-media-pvc` (for media files)

2. **Same storage configuration**:
   - Config PVC still uses Longhorn storage class
   - Media PVC still uses NFS mount to your NAS

3. **Kubernetes will reuse existing PVCs**: When you redeploy, Kubernetes will find the existing PVCs with the same names and reattach them to the pods, preserving all data.

## How to Deploy

### Option 1: Deploy all applications
```bash
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml --ask-vault-pass
```

### Option 2: Deploy only Jellyfin
```bash
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml --tags jellyfin --ask-vault-pass
```

## Verification

After deployment, verify everything is working:

```bash
# Check namespace
kubectl get namespace jellyfin

# Check PVCs (should show existing ones)
kubectl get pvc -n jellyfin

# Check deployment
kubectl get deployment -n jellyfin

# Check certificate
kubectl get certificate -n jellyfin

# Check ingress
kubectl get ingress -n jellyfin

# Check pods
kubectl get pods -n jellyfin
```

## Benefits

1. **Less code**: Removed 3 template files (~150 lines)
2. **Consistency**: Uses same patterns as other apps
3. **Maintainability**: Bug fixes in `common_k8s` benefit all apps
4. **Validation**: Built-in variable validation with helpful error messages

## Rollback (if needed)

If you need to rollback, the previous version is in git history:
```bash
git log --oneline roles/app_jellyfin/
git checkout <commit-hash> roles/app_jellyfin/
```

However, rollback should not be necessary as the migration is backward-compatible.

