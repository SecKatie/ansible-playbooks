# Ansible Playbooks Repository Guide

## Commands

### Testing
- Full role test: `molecule test -c roles/ROLE_NAME/molecule/default/molecule.yml`
- Test single role: `cd roles/ROLE_NAME && molecule test`
- Skip destroy after test: `molecule test --destroy=never`
- Verify only: `molecule verify`
- Converge only: `molecule converge`

### Linting
- Lint all playbooks: `ansible-lint`
- Lint specific playbook: `ansible-lint playbooks/FILE.yml`
- Lint YAML files: `yamllint .`

### Execution
- Run playbook: `ansible-playbook playbooks/site.yml -i inventory/raspberrypi.yml -K`
- Run with verbose output: `ansible-playbook playbooks/site.yml -vvv -i inventory/raspberrypi.yml -K`

## Code Style Guidelines

### YAML
- Use 2-space indentation
- Keep lines under 160 characters
- Use `>` for multi-line strings with newlines folded
- Use `|` for multi-line strings where newlines matter

### Ansible Best Practices
- Task names should be descriptive and follow sentence case
- Use module FQCN (fully qualified collection names)
- Always set `changed_when` for commands
- Separate big tasks into smaller included tasks
- Use handlers for service restarts
- Use clear, descriptive variable names (snake_case)
- Add comments for complex tasks or variable usage