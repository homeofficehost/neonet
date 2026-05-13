# Authentication & Security Options

This project includes optional configurations to reduce authentication prompts. **These features are disabled by default for security reasons.**

## Available Options

Controlled via `group_vars/all`:

```yaml
# WARNING: Reduces system security. Only enable in trusted environments.
enable_passwordless_sudo: false
enable_auto_login:        false
```

### Passwordless Sudo (`enable_passwordless_sudo`)

When enabled, the user will not be prompted for a password when running `sudo` commands.

**Security impact**: Any process running as your user can execute commands with root privileges without authentication. This includes compromised applications or malicious scripts.

**Use case**: Development workstations where frequent sudo commands are needed and physical access is controlled.

### Auto-Login (`enable_auto_login`)

When enabled, macOS will boot directly to the desktop without requiring a password at the login screen.

**Security impact**: Anyone with physical access to the machine can access all data immediately. Screen saver password prompts are also disabled.

**Use case**: Single-user desktops in secure locations, or systems where convenience outweighs physical security concerns.

## Enabling These Options

1. Edit `group_vars/all`
2. Set the desired variable(s) to `true`
3. Re-run the playbook:
   ```bash
   ansible-playbook -i hosts local.yml --limit $(hostname -s).local --tags base
   ```

Or run only the specific tag:
```bash
ansible-playbook -i hosts local.yml --limit $(hostname -s).local --tags sudo
ansible-playbook -i hosts local.yml --limit $(hostname -s).local --tags login
```

## Reverting

Set the variable back to `false` and re-run. The playbook will remove the passwordless sudo entry and disable auto-login.
