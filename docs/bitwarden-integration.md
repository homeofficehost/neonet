# Bitwarden Secrets Management

This document describes the Bitwarden CLI integration for secrets management in this dotfiles project.

## Overview

Secrets are stored in Bitwarden under the `neonet` organization folder, with subfolders per host.

## Folder Structure

```
neonet/
└── tgworkmac/          # Host-specific secrets
    ├── vault_key       # Ansible Vault password
    ├── ssh_key_passphrase
    └── gpg_passphrase
```

## Setup

### 1. Login to Bitwarden CLI

```bash
bw login
bw unlock
```

### 2. Export Session Key

After unlocking, export the session key to your environment:

```bash
export BW_SESSION="your-session-key-here"
```

Add this to your `.zshrc` or `.bashrc` for persistence.

### 3. Running Bootstrap

The bootstrap script automatically retrieves `vault_key` from Bitwarden:

```bash
./bootstrap.sh
```

## Adding New Hosts

### 1. Create Host Folder in Bitwarden

```bash
# Create the folder structure
echo '{"name":"neonet/hostname"}' | base64 | bw create folder
```

### 2. Create Secrets

Create items in the new folder with the following structure:

```json
{
  "name": "vault_key",
  "type": 1,
  "login": {
    "username": "hostname",
    "password": "your-vault-password"
  }
}
```

Required items per host:
- `vault_key` - Ansible Vault password
- `ssh_key_passphrase` - SSH key passphrase (optional)
- `gpg_passphrase` - GPG key passphrase (optional)

### 3. Add Host to Inventory

Edit `hosts` file:

```ini
[base]
hostname.local ansible_sudo=True

[workstation]
hostname.local ansible_sudo=True
```

### 4. Create Host Variables

Create `host_vars/hostname.local` with host-specific variables.

## Bitwarden CLI Commands

```bash
# List folders
bw list folders

# List items in folder
bw list items --folderid <folder-id>

# Get item password
bw get item <item-name> | jq -r '.login.password'

# Create item
echo '{"name":"item-name","type":1,"login":{"password":"secret"}}' | base64 | bw create item

# Check login status
bw login --check
```

## Security Notes

- Never commit `BW_SESSION` to git
- Session keys expire - re-run `bw unlock` when needed
- Consider using `bw lock` after bootstrap completes
