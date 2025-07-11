# Update Packages Playbook with Ntfy Notifications

The `maintenance-update-packages.yml` playbook has been enhanced with comprehensive ntfy notification support to keep you informed about system updates in real-time.

## 🔔 Notification Features

### What You'll Receive

1. **Update Start** (optional): Notification when updates begin on a server
2. **Update Success**: Confirmation when updates complete successfully
3. **Reboot Required**: Alert when servers need rebooting after updates
4. **Update Failures**: Urgent alerts if updates fail
5. **Summary Report**: Overview of all updates completed

### Notification Types

#### ✅ Success Notifications
- **Priority**: Normal (High if reboot required)
- **Tags**: `white_check_mark,package`
- **Includes**: Server name, OS info, timestamp, reboot status

#### ⚠️ Reboot Required
- **Priority**: High
- **Tags**: `warning,arrows_counterclockwise` 
- **Includes**: Reboot command, documentation link
- **Action Button**: Link to reboot documentation

#### ❌ Failure Notifications
- **Priority**: Urgent
- **Tags**: `x,package,rotating_light`
- **Includes**: Error details, failed task info

#### 📊 Summary Report
- **Priority**: Normal
- **Tags**: `clipboard,white_check_mark`
- **Includes**: Total servers, completion count, reboot list

## 🚀 Usage

### Basic Usage (Default Notifications)
```bash
ansible-playbook playbooks/maintenance-update-packages.yml
```

### Customized Notifications
```bash
ansible-playbook playbooks/maintenance-update-packages.yml \
  -e ntfy_update_topic="my_server_alerts" \
  -e ntfy_notify_start=true \
  -e ntfy_summary=true
```

### Disable Notifications
```bash
ansible-playbook playbooks/maintenance-update-packages.yml \
  -e ntfy_summary=false \
  -e ntfy_notify_reboot=false
```

## ⚙️ Configuration Variables

### Notification Topic
- **Variable**: `ntfy_update_topic`
- **Default**: `ee4ccfad-efdb-4862-8f38-d7455bcbd198` (authenticated topic)
- **Usage**: Set your custom ntfy topic

### Authentication
- **Built-in**: Uses Bearer token authentication for secure notifications
- **Topic**: Private authenticated topic for enhanced security

### Start Notifications
- **Variable**: `ntfy_notify_start`
- **Default**: `false`
- **Usage**: Enable notifications when updates start

### Reboot Notifications
- **Variable**: `ntfy_notify_reboot`
- **Default**: `true`
- **Usage**: Alert when reboots are required

### Summary Report
- **Variable**: `ntfy_summary`
- **Default**: `true`
- **Usage**: Send final summary of all updates

## 📱 Setup Instructions

### 1. Subscribe to Notifications
- **Topic ID**: `ee4ccfad-efdb-4862-8f38-d7455bcbd198`
- **Mobile**: Install ntfy app, subscribe to the topic above
- **Desktop**: Visit `https://ntfy.sh/ee4ccfad-efdb-4862-8f38-d7455bcbd198`
- **Security**: This is a private, authenticated topic for secure notifications

### 2. Test Notifications
```bash
# Test the ntfy role first
ansible-playbook playbooks/testing-notification-system.yml

# Then run a small update test
ansible-playbook playbooks/maintenance-update-packages.yml -l localhost
```

### 3. Production Use
```bash
# Update all servers with notifications
ansible-playbook playbooks/maintenance-update-packages.yml

# Update specific group
ansible-playbook playbooks/maintenance-update-packages.yml -l raspberrypi
```

## 🎯 Example Notifications

### Successful Update
```
✅ Package update completed successfully!

Server: super6c-node-1
OS: Ubuntu 22.04
Time: 2024-01-15T14:30:00Z
```

### Reboot Required
```
🔄 Reboot Required

Server: super6c-node-1 has completed updates but requires a reboot.

To reboot: ansible-playbook playbooks/maintenance-reboot-systems.yml -l super6c-node-1
```

### Update Summary
```
📊 Update Summary Report

Total servers: 4
Completed: 4
Time: 2024-01-15T14:35:00Z

Servers requiring reboot:
- super6c-node-1
- super6c-node-2
```

## 🔧 Integration with Other Playbooks

The notification system can be easily adapted for other playbooks:

```yaml
# In any playbook
- name: Send completion notification
  include_role:
    name: ntfy_notify
  vars:
    ntfy_topic: "{{ ntfy_update_topic | default('server_updates') }}"
    ntfy_message: "Operation completed on {{ inventory_hostname }}"
    ntfy_title: "Task Complete"
  delegate_to: localhost
```

## 🚨 Troubleshooting

### No Notifications Received
1. Check ntfy topic subscription
2. Verify internet connectivity
3. Test with `playbooks/testing-notification-system.yml`

### Notification Errors
1. Check Ansible logs for HTTP errors
2. Verify ntfy.sh service status
3. Test with `playbooks/testing-notification-system.yml`
   3.1. Test manual curl command:
      ```bash
      curl -d "Test message" ntfy.sh/server_updates
      ```

### Custom Server
To use your own ntfy server, set in group_vars or host_vars:
```yaml
ntfy_server: "https://ntfy.yourdomain.com"
``` 