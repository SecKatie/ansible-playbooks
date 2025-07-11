# Molecule Testing for Ansible Roles

This document describes the molecule testing setup for all roles in this Ansible project.

## What is Molecule?

Molecule is a testing framework for Ansible roles that allows you to test your roles in isolated environments using Docker containers. It helps ensure your roles work correctly across different platforms and configurations.

## Setup

### Prerequisites

Make sure you have Docker installed and running on your system.

### Installation

Install the required dependencies:

```bash
pip install -r requirements.txt
```

This will install:
- `molecule[docker]` - Molecule with Docker driver
- `molecule-plugins[docker]` - Docker plugins for Molecule
- `docker` - Docker Python SDK

## Running Tests

### Test a Single Role

To test a specific role, navigate to the role directory and run molecule:

```bash
cd roles/system_update
molecule test
```

### Test All Roles

To test all roles in the project:

```bash
for role in roles/*/; do
    echo "Testing $(basename "$role")..."
    (cd "$role" && molecule test) || echo "Failed to test $(basename "$role")"
done
```

### Available Molecule Commands

- `molecule test` - Run the full test suite (recommended)
- `molecule converge` - Run the role without destroying the container
- `molecule verify` - Run verification tests
- `molecule destroy` - Clean up test containers
- `molecule lint` - Run linting checks
- `molecule list` - List available test instances

## Test Structure

Each role has a molecule configuration in `roles/<role_name>/molecule/default/`:

```
roles/
├── system_update/
│   └── molecule/
│       └── default/
│           ├── molecule.yml    # Main configuration
│           ├── converge.yml    # Playbook to test the role
│           └── verify.yml      # Verification tests
└── ...
```

### Key Files

- **molecule.yml**: Main configuration file that defines:
  - Docker driver settings
  - Test platforms (container images)
  - Test sequence steps
  
- **converge.yml**: Playbook that runs your role with appropriate variables
  
- **verify.yml**: Verification tests to ensure the role worked correctly

## Role-Specific Testing

### system_update Role

The `system_update` role has enhanced testing that:
- Tests on both Debian and RedHat family systems
- Verifies package updates are logged
- Checks for reboot requirements
- Uses privileged containers for system-level operations

### ntfy_notify Role

The `ntfy_notify` role testing includes:
- Mock HTTP endpoint for notification testing
- Variable validation testing
- Error handling verification

### reboot Role

The `reboot` role testing:
- Uses privileged containers with systemd
- Verifies system responsiveness after reboot
- Tests systemd service functionality

### Other Roles

All other roles use basic testing configurations that:
- Verify the role executes without errors
- Check system responsiveness
- Provide foundation for future enhanced testing

## Customizing Tests

### Adding Platform Support

To test a role on additional platforms, edit the `molecule.yml` file:

```yaml
platforms:
  - name: instance-ubuntu
    image: ubuntu:20.04
    pre_build_image: true
  - name: instance-centos
    image: centos:8
    pre_build_image: true
```

### Adding Test Variables

Customize the `converge.yml` file to test different variable combinations:

```yaml
vars:
  # Test-specific variables
  test_mode: true
  custom_setting: "test_value"
```

### Enhanced Verification

Add more comprehensive tests in `verify.yml`:

```yaml
tasks:
  - name: Check if service is running
    ansible.builtin.systemd:
      name: myservice
      state: started
    register: service_check
    
  - name: Verify service is active
    ansible.builtin.assert:
      that:
        - service_check.status.ActiveState == "active"
```

## Troubleshooting

### Common Issues

1. **Docker not running**: Ensure Docker daemon is running
2. **Permission issues**: Run with appropriate privileges or add user to docker group
3. **Image pull failures**: Check internet connectivity and image availability
4. **Container startup failures**: Review container logs with `molecule list` and `docker logs`

### Debugging

For debugging failed tests:

```bash
# Keep containers running after test
molecule converge

# Check container status
molecule list

# Login to test container
molecule login

# View logs
molecule --debug test
```

## CI/CD Integration

You can integrate molecule testing into your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
name: Molecule Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.8
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run molecule tests
        run: |
          for role in roles/*/; do
            (cd "$role" && molecule test)
          done
```

## Best Practices

1. **Test early and often**: Run tests during development
2. **Use realistic scenarios**: Test with variables similar to production
3. **Test edge cases**: Include tests for error conditions
4. **Keep tests fast**: Use lightweight containers when possible
5. **Document test requirements**: Add comments explaining complex test scenarios

## Next Steps

1. **Enhanced testing**: Add more comprehensive tests for complex roles
2. **Multi-platform testing**: Test on more operating systems
3. **Integration testing**: Test role interactions
4. **Performance testing**: Add timing and resource usage tests
5. **Security testing**: Include security validation tests

For more information, see the [Molecule documentation](https://molecule.readthedocs.io/).