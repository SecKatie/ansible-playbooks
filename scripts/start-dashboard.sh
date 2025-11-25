#!/bin/bash

# Start port-forward to dashboard in the background
echo "Starting Kubernetes Dashboard port-forward..."
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 &
PROXY_PID=$!
echo "Port-forward started with PID: $PROXY_PID"

# Wait a moment for port-forward to start
sleep 2

# Get the admin token from kubernetes-dashboard
echo "Retrieving admin token..."
TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user 2>/dev/null)

if [ -z "$TOKEN" ]; then
  # Try alternative method if token creation fails
  TOKEN=$(kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}') -o jsonpath="{.data.token}" | base64 --decode 2>/dev/null)
fi

if [ -z "$TOKEN" ]; then
  echo "Error: Could not retrieve admin token"
  kill $PROXY_PID
  exit 1
fi

# Copy token to clipboard
echo "$TOKEN" | pbcopy
echo "Admin token copied to clipboard!"

# Display info
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kubernetes Dashboard is ready!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dashboard URL: https://localhost:8443"
echo ""
echo "Token copied to clipboard (paste with Cmd+V)"
echo ""
echo "Port-forward is running in background (PID: $PROXY_PID)"
echo "To stop: kill $PROXY_PID"
echo ""
