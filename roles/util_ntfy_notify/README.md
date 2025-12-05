# Ntfy Notify Role

An Ansible role for sending notifications using the [ntfy.sh](https://ntfy.sh) service.

## Description

This role allows you to send push notifications to your devices using ntfy.sh. It supports all major ntfy features including:
- Message titles and priorities
- Tags and emojis
- Click actions
- File attachments
- Email notifications
- Scheduled delivery
- Action buttons
- Markdown formatting

## Requirements

- Ansible 2.9 or higher
- Internet connectivity to reach ntfy.sh (or your self-hosted ntfy server)
- `ansible.builtin.uri` module (included in Ansible core)

## Role Variables

### Required Variables

- `ntfy_topic`: The ntfy topic to publish to (acts as a password)
- `ntfy_message`: The message content to send

### Optional Variables

#### Server Configuration
- `ntfy_server`: ntfy server URL (default: `https://ntfy.sh`)
- `ntfy_auth`: Authentication header for protected topics

#### Message Configuration
- `ntfy_title`: Message title
- `ntfy_priority`: Message priority (`min`, `low`, `default`, `high`, `urgent`)
- `ntfy_tags`: Comma-separated list of tags/emojis
- `ntfy_markdown`: Enable Markdown formatting (boolean)

#### Actions and Links
- `ntfy_click_url`: URL to open when notification is clicked
- `ntfy_attach_url`: URL of file to attach
- `ntfy_actions`: Action buttons configuration
- `ntfy_email`: Email address for email notifications

#### Scheduling
- `ntfy_delay`: Delay delivery (e.g., "30min" or timestamp)

#### Visual
- `ntfy_icon`: URL of custom notification icon

#### Behavior
- `ntfy_debug`: Show debug information (default: `false`)
- `ntfy_fail_on_error`: Fail playbook on notification error (default: `true`)
- `ntfy_timeout`: HTTP request timeout in seconds (default: `30`)

## Example Playbook

### Basic Notification

```yaml
- hosts: localhost
  roles:
    - role: ntfy_notify
      vars:
        ntfy_topic: "myserver_alerts"
        ntfy_message: "Deployment completed successfully!"
```

### Advanced Notification with All Features

```yaml
- hosts: localhost
  roles:
    - role: ntfy_notify
      vars:
        ntfy_topic: "server_monitoring"
        ntfy_message: |
          Server maintenance completed.
          
          All services have been restarted and are running normally.
        ntfy_title: "Maintenance Complete"
        ntfy_priority: "high"
        ntfy_tags: "white_check_mark,server"
        ntfy_click_url: "https://status.myserver.com"
        ntfy_email: "admin@example.com"
        ntfy_markdown: true
        ntfy_actions: "http, Check Status, https://status.myserver.com/health, clear=true"
```

### Using with Authentication

```yaml
- hosts: localhost
  roles:
    - role: ntfy_notify
      vars:
        ntfy_server: "https://ntfy.mycompany.com"
        ntfy_topic: "private_alerts"
        ntfy_message: "Confidential notification"
        ntfy_auth: "Bearer YOUR_ACCESS_TOKEN"
```

### Conditional Notifications

```yaml
- hosts: all
  tasks:
    - name: Check disk space
      ansible.builtin.shell: df / | tail -1 | awk '{print $5}' | sed 's/%//'
      register: disk_usage
      
    - name: Send alert if disk usage is high
      include_role:
        name: ntfy_notify
      vars:
        ntfy_topic: "server_alerts"
        ntfy_message: "High disk usage detected: {{ disk_usage.stdout }}% on {{ inventory_hostname }}"
        ntfy_title: "Disk Space Alert"
        ntfy_priority: "urgent"
        ntfy_tags: "warning,hdd"
      when: disk_usage.stdout | int > 80
```

### Using in Handlers

```yaml
- hosts: all
  handlers:
    - name: notify deployment success
      include_role:
        name: ntfy_notify
      vars:
        ntfy_topic: "deployments"
        ntfy_message: "Application deployed successfully to {{ inventory_hostname }}"
        ntfy_title: "Deployment Success"
        ntfy_tags: "rocket,white_check_mark"

  tasks:
    - name: Deploy application
      ansible.builtin.copy:
        src: app.jar
        dest: /opt/app/
      notify: notify deployment success
```

## Priority Levels

- `min`: Lowest priority, typically no sound/vibration
- `low`: Low priority, may not wake up the device
- `default`: Default priority level
- `high`: High priority, typically with sound/vibration
- `urgent`: Highest priority, bypasses Do Not Disturb

## Tags and Emojis

You can use any emoji shortcode or custom tags. Popular examples:
- `warning,skull` - Warning with skull emoji
- `white_check_mark,rocket` - Success with checkmark and rocket
- `rotating_light,fire` - Emergency alert
- `information_source` - Information notice

## Action Buttons

Action buttons allow users to interact directly from the notification. Format:
```
"action_type, Label, URL/broadcast, clear=true"
```

Types:
- `http`: Make HTTP request
- `broadcast`: Send Android broadcast
- `view`: Open URL

## License

MIT

## Author Information

Created for use with ntfy.sh notification service. 