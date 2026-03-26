# dotfiles

Configuration and automation for tgworkstation (macOS 14 Sonoma).

## Prerequisites

Before running the setup, ensure you have:

1. **macOS 14 Sonoma** (or later)
2. **Administrator access** (sudo privileges)
3. **Internet connection**
4. **GitHub account** with SSH keys (for automatic SSH key download)
5. **Optional**: `~/.vault_key` file if you have encrypted Ansible vault files

## Quick Setup

### Option 1: One-liner (Recommended)

```bash
curl -Lks https://raw.githubusercontent.com/homeofficehost/neonet/master/bootstrap.sh | /bin/bash
```

### Option 2: Clone and Run

```bash
# Clone the repository
git clone https://github.com/homeofficehost/neonet.git ~/.dotfiles

# Navigate to the directory
cd ~/.dotfiles

# Run the bootstrap script
./bootstrap.sh
```

## What Happens During Setup

The bootstrap script will:

1. **Install Homebrew** (if not present)
2. **Install Ansible** via Homebrew
3. **Install `pass` (password store)**
4. **Clone password store** from your GitLab repository
5. **Run ansible-pull** to configure the system:
   - Set up user environment
   - Download SSH keys from GitHub (thomasgroch)
   - Install packages from Brewfile
   - Configure dotfiles bare repository
   - Set up cron jobs for automatic updates

## Manual Usage

### Run ansible-pull manually

```bash
# With vault password (if you have encrypted files)
ansible-pull --vault-password-file ~/.vault_key \
  --url https://github.com/homeofficehost/neonet \
  --limit $(hostname -s).local

# Without vault password
ansible-pull --url https://github.com/homeofficehost/neonet \
  --limit $(hostname -s).local
```

### Using tags to run specific parts

```bash
# Run only base role (system setup)
ansible-pull --url https://github.com/homeofficehost/neonet \
  --limit $(hostname -s).local --tags base

# Run only workstation role (applications)
ansible-pull --url https://github.com/homeofficehost/neonet \
  --limit $(hostname -s).local --tags workstation
```

## Whats Included

### Core Components

- **Ansible** - Infrastructure as code automation
- **Homebrew** - Package management
- **Brewfile** - Declarative package installation
- **Bare Git Repository** - Dotfiles version control

### Configuration Managed

- **Shell**: zsh configuration
- **SSH**: Keys downloaded from GitHub
- **Git**: Personal configs and aliases
- **Cron**: Automatic daily updates
- **Applications**: All packages from Brewfile

### Automatic Features

- **SSH Key Sync**: Downloads public keys from GitHub (thomasgroch)
- **Daily Updates**: Cron job runs ansible-pull every 30 minutes
- **Self-healing**: Reapplies configuration if drift detected

## Project Structure

```
neonet/
├── ansible.cfg          # Ansible configuration
├── bootstrap.sh         # Initial setup script
├── Brewfile             # Homebrew packages
├── hosts                # Ansible inventory
├── local.yml            # Main playbook
├── README.md            # This file
├── roles/
│   ├── base/            # Base system configuration
│   └── workstation/     # User applications
├── group_vars/all       # Variables (GitHub username, etc.)
└── linux/               # Linux-specific files (reference)
```

## Troubleshooting

### Bootstrap fails with permission errors

Ensure you are running with a user that has sudo privileges:
```bash
sudo -v
```

### Ansible vault decryption fails

If you have encrypted files, create the vault key file:
```bash
echo "your-vault-password" > ~/.vault_key
chmod 600 ~/.vault_key
```

### SSH keys not downloaded

Check if `github_username` is set correctly in `group_vars/all`:
```bash
grep github_username group_vars/all
```

Should show: `github_username: "thomasgroch"`

### Homebrew not found after installation

Add Homebrew to your PATH:
```bash
# For Apple Silicon (M1/M2/M3)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

## Development

### Testing locally

```bash
# Run Docker tests
./docker-test.sh

# Check syntax
ansible-playbook --syntax-check -i hosts local.yml

# Dry run
ansible-playbook --check -i hosts local.yml
```

### CI/CD

This project uses GitHub Actions for testing:
- Syntax validation
- macOS runner tests
- Docker container tests

See `.github/workflows/test-macos.yml`

## Security

- **SSH Keys**: Downloaded only from trusted GitHub account
- **Vault**: Sensitive data encrypted with Ansible Vault
- **Sudo**: Script requests sudo only when needed
- **Permissions**: Proper file permissions enforced

## License

MIT
