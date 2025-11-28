# Ansible Playbooks - Task Runner

# Get Kubernetes Dashboard admin token and copy to clipboard
dashboard-token:
    @kubectl get secret admin-user-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d | pbcopy
    @echo "Dashboard token copied to clipboard"
