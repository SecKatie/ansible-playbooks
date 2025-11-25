# Sonarr Proxy Scripts

This directory contains utility scripts for managing port forwarding to Sonarr endpoints in Kubernetes.

## sonarr-proxies.sh

A comprehensive port forwarding manager that handles all Sonarr-related services.

### Prerequisites

- `kubectl` installed and configured with access to your cluster
- The `sonarr` namespace must exist with the Sonarr deployment running

### Usage

```bash
./sonarr-proxies.sh start        # Start all port forwards
./sonarr-proxies.sh stop         # Stop all port forwards
./sonarr-proxies.sh status       # Show status of port forwards
./sonarr-proxies.sh restart      # Restart all port forwards
./sonarr-proxies.sh help         # Show help message
```

### Managed Endpoints

The script manages port forwarding for the following Sonarr endpoints:

| Service | Local Port | Target | Purpose |
|---------|-----------|--------|---------|
| **Sonarr** | 8989 | 8989 | TV show PVR management |
| **qBittorrent** | 8080 | 8080 | Torrent download client |
| **Jackett** | 9117 | 9117 | Torrent indexer proxy |
| **FlareSolverr** | 8191 | 8191 | Cloudflare challenge solver |
| **Gluetun** | 8000 | 8000 | VPN control interface |

### Features

- **Persistent Process Tracking**: Uses PID files to track running port-forwards
- **Status Monitoring**: Check which proxies are running
- **Graceful Startup/Shutdown**: Properly manages process lifecycle
- **Color-coded Output**: Easy-to-read status messages
- **Error Handling**: Validates kubectl availability and namespace existence

### Examples

**Start all proxies:**
```bash
./sonarr-proxies.sh start
# Output:
# Starting Sonarr port forwards...
# ✓ sonarr (localhost:8989 → 8989)
# ✓ qbittorrent (localhost:8080 → 8080)
# ✓ jackett (localhost:9117 → 9117)
# ✓ flaresolver (localhost:8191 → 8191)
# ✓ gluetun (localhost:8000 → 8000)
#
# All port forwards started!
# Access endpoints at:
#   Sonarr:        http://localhost:8989
#   qBittorrent:   http://localhost:8080
#   Jackett:       http://localhost:9117
#   FlareSolverr:  http://localhost:8191
#   Gluetun:       http://localhost:8000
```

**Check status:**
```bash
./sonarr-proxies.sh status
# Output shows which proxies are running with their PIDs
```

**Stop all proxies:**
```bash
./sonarr-proxies.sh stop
```

### PID File Storage

The script stores PID files in `~/.sonarr-proxies/` directory to track running port-forward processes. These are automatically created and cleaned up as needed.

### Troubleshooting

**"kubectl not found" error:**
- Install kubectl: `brew install kubernetes-cli` (macOS) or see https://kubernetes.io/docs/tasks/tools/

**"Namespace 'sonarr' does not exist" error:**
- Ensure the Sonarr deployment is running: `kubectl get ns | grep sonarr`
- Deploy Sonarr if needed using the Ansible playbooks

**Port already in use:**
- Another process is using one of the target ports
- Stop the conflicting process or modify the local port in the script
- Check: `lsof -i :8989` to see what's using the port

**Port forwards not connecting:**
- Verify the sonarr pod is running: `kubectl get pods -n sonarr`
- Check pod logs: `kubectl logs -n sonarr deployment/sonarr`
- Ensure you have network access to the cluster

### Setup for Convenience

To use the script from anywhere, you can:

1. **Add to PATH** (recommended):
   ```bash
   export PATH="${PATH}:$(pwd)"
   sonarr-proxies.sh start
   ```

2. **Create an alias**:
   ```bash
   alias sonarr-proxy='~/.../scripts/sonarr-proxies.sh'
   sonarr-proxy start
   ```

3. **Run directly from repo**:
   ```bash
   cd /path/to/ansible-playbooks
   ./scripts/sonarr-proxies.sh start
   ```
