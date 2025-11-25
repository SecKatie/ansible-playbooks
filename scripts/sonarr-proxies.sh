#!/bin/bash

##############################################################################
# Media Stack Port Forward Proxy Manager
#
# This script manages port forwarding for the media stack endpoints.
# It sets up kubectl port-forward commands for:
#  - Sonarr (8989) - NO VPN
#  - Radarr (7878) - NO VPN
#  - qBittorrent (8080) - WITH VPN
#  - SABnzbd (8085) - WITH VPN
#  - Jackett (9117) - WITH VPN
#  - Gluetun VPN Control (8000) - WITH VPN
#
# Usage:
#   ./sonarr-proxies.sh start   - Start all port forwards
#   ./sonarr-proxies.sh stop    - Stop all port forwards
#   ./sonarr-proxies.sh status  - Show status of port forwards
#   ./sonarr-proxies.sh restart - Restart all port forwards
##############################################################################

set -e

# Configuration
NAMESPACE="sonarr"
PIDFILE_DIR="${HOME}/.media-proxies"

# Define endpoints: name, service_name, local_port, container_port
declare -a ENDPOINTS=(
  "sonarr:sonarr:8989:8989"
  "radarr:radarr:7878:7878"
  "qbittorrent:downloads:8080:8080"
  "sabnzbd:downloads:8085:8085"
  "jackett:downloads:9117:9117"
  "gluetun:downloads:8000:8000"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

##############################################################################
# Functions
##############################################################################

# Create pidfile directory if it doesn't exist
ensure_pidfile_dir() {
  mkdir -p "${PIDFILE_DIR}"
}

# Get pidfile path for an endpoint
get_pidfile() {
  local endpoint_name=$1
  echo "${PIDFILE_DIR}/${endpoint_name}.pid"
}

# Check if kubectl is available
check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found. Please install kubectl.${NC}"
    exit 1
  fi
}

# Check if the namespace exists
check_namespace() {
  if ! kubectl get namespace "${NAMESPACE}" &> /dev/null; then
    echo -e "${RED}Error: Namespace '${NAMESPACE}' does not exist.${NC}"
    exit 1
  fi
}

# Start a single port forward
start_port_forward() {
  local endpoint_name=$1
  local service_name=$2
  local local_port=$3
  local container_port=$4
  local pidfile=$(get_pidfile "${endpoint_name}")

  # Check if already running
  if [ -f "${pidfile}" ]; then
    local pid=$(cat "${pidfile}")
    if kill -0 "${pid}" 2>/dev/null; then
      echo -e "${YELLOW}⚠ ${endpoint_name} (${local_port}): Already running (PID: ${pid})${NC}"
      return 0
    else
      rm -f "${pidfile}"
    fi
  fi

  # Start port forward
  kubectl -n "${NAMESPACE}" port-forward svc/"${service_name}" \
    "${local_port}:${container_port}" > /dev/null 2>&1 &
  local pid=$!
  echo "${pid}" > "${pidfile}"
  echo -e "${GREEN}✓ ${endpoint_name} (localhost:${local_port} → svc/${service_name}:${container_port})${NC}"
}

# Stop a single port forward
stop_port_forward() {
  local endpoint_name=$1
  local pidfile=$(get_pidfile "${endpoint_name}")

  if [ -f "${pidfile}" ]; then
    local pid=$(cat "${pidfile}")
    if kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" 2>/dev/null || true
      rm -f "${pidfile}"
      echo -e "${GREEN}✓ ${endpoint_name}: Stopped${NC}"
    else
      rm -f "${pidfile}"
      echo -e "${YELLOW}⚠ ${endpoint_name}: Was not running${NC}"
    fi
  else
    echo -e "${YELLOW}⚠ ${endpoint_name}: No PID file found${NC}"
  fi
}

# Get status of a single port forward
get_port_forward_status() {
  local endpoint_name=$1
  local local_port=$2
  local pidfile=$(get_pidfile "${endpoint_name}")

  if [ -f "${pidfile}" ]; then
    local pid=$(cat "${pidfile}")
    if kill -0 "${pid}" 2>/dev/null; then
      echo -e "${GREEN}✓ ${endpoint_name} (localhost:${local_port})${NC} - Running (PID: ${pid})"
      return 0
    else
      rm -f "${pidfile}"
      echo -e "${RED}✗ ${endpoint_name} (localhost:${local_port})${NC} - PID ${pid} not found"
      return 1
    fi
  else
    echo -e "${RED}✗ ${endpoint_name} (localhost:${local_port})${NC} - Not running"
    return 1
  fi
}

# Start all port forwards
start_all() {
  echo -e "${BLUE}Starting Media Stack port forwards...${NC}"
  check_kubectl
  check_namespace
  ensure_pidfile_dir

  for endpoint in "${ENDPOINTS[@]}"; do
    IFS=':' read -r name service local_port container_port <<< "${endpoint}"
    start_port_forward "${name}" "${service}" "${local_port}" "${container_port}"
  done

  echo -e "${BLUE}All port forwards started!${NC}"
  echo -e "${BLUE}Access endpoints at:${NC}"
  echo "  📺 Sonarr (TV):     http://localhost:8989"
  echo "  🎬 Radarr (Movies): http://localhost:7878"
  echo "  ⬇️  qBittorrent:     http://localhost:8080"
  echo "  📰 SABnzbd:         http://localhost:8085"
  echo "  🔍 Jackett:         http://localhost:9117"
  echo "  🔒 Gluetun VPN:     http://localhost:8000"
}

# Stop all port forwards
stop_all() {
  echo -e "${BLUE}Stopping Media Stack port forwards...${NC}"

  for endpoint in "${ENDPOINTS[@]}"; do
    IFS=':' read -r name _ _ _ <<< "${endpoint}"
    stop_port_forward "${name}"
  done

  echo -e "${BLUE}All port forwards stopped!${NC}"
}

# Get status of all port forwards
status_all() {
  echo -e "${BLUE}Media Stack port forward status:${NC}"
  echo "================================"

  local all_running=true
  for endpoint in "${ENDPOINTS[@]}"; do
    IFS=':' read -r name _ local_port _ <<< "${endpoint}"
    if ! get_port_forward_status "${name}" "${local_port}"; then
      all_running=false
    fi
  done

  echo "================================"
  if [ "${all_running}" = true ]; then
    echo -e "${GREEN}All port forwards are running${NC}"
    return 0
  else
    echo -e "${RED}Some port forwards are not running${NC}"
    return 1
  fi
}

# Restart all port forwards
restart_all() {
  stop_all
  echo ""
  sleep 1
  start_all
}

# Show help
show_help() {
  cat << EOF
${BLUE}Media Stack Port Forward Proxy Manager${NC}

Usage: $0 [COMMAND]

Commands:
  start        Start all port forwards
  stop         Stop all port forwards
  status       Show status of all port forwards
  restart      Restart all port forwards
  help         Show this help message

Examples:
  $0 start      # Start all proxies
  $0 status     # Check status
  $0 stop       # Stop all proxies

Endpoints:
  📺 Sonarr (TV Shows)     → localhost:8989 (NO VPN)
  🎬 Radarr (Movies)       → localhost:7878 (NO VPN)
  ⬇️  qBittorrent          → localhost:8080 (WITH VPN)
  📰 SABnzbd (Usenet)      → localhost:8085 (WITH VPN)
  🔍 Jackett (Indexers)    → localhost:9117 (WITH VPN)
  🔒 Gluetun VPN Control   → localhost:8000 (WITH VPN)

EOF
}

##############################################################################
# Main
##############################################################################

main() {
  local command="${1:-help}"

  case "${command}" in
    start)
      start_all
      ;;
    stop)
      stop_all
      ;;
    status)
      status_all
      ;;
    restart)
      restart_all
      ;;
    help)
      show_help
      ;;
    *)
      echo -e "${RED}Unknown command: ${command}${NC}"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

main "$@"
