# dotfiles

Configuration and automation for tgworkmac (macOS 26).

## Prerequisites

Before running the setup, ensure you have:

1. **macOS 26** (or later)
2. **Administrator access** (sudo privileges)
3. **Internet connection**
4. **GitHub account** with access to the configured repositories
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
3. **Install Bitwarden CLI** for password management
4. **Run ansible-pull against localhost** to configure the system:
   - Set up user environment
   - Install packages from Brewfile
   - Configure dotfiles bare repository
   - Install the generated `/usr/local/bin/provision` script
   - Schedule a cron job that runs it daily at 06:00

## Manual Usage

Ansible runs once and exits — it does not stay running in the background. The
cron job simply re-triggers provisioning daily at 06:00 by running
`/usr/local/bin/provision`, which re-runs ansible-pull against localhost and
reapplies any configuration that has drifted.

All entrypoints (bootstrap, `run.sh`, `/usr/local/bin/provision`, cron) append
their output to `~/ansible_provision.log`.

### Run the playbook manually

Run the local wrapper, which calls `ansible-playbook -i localhost, local.yml`:

```bash
./run.sh
```

With a vault password (if you have encrypted files):

```bash
./run.sh --vault-password-file ~/.vault_key
```

Or run the generated provision script — the same one cron triggers:

```bash
/usr/local/bin/provision
```

### Using tags to run specific parts

```bash
# Run only the base role (system setup)
./run.sh --tags base

# Run only the workstation role (applications)
./run.sh --tags workstation
```

The provision script also accepts a single tag argument:

```bash
/usr/local/bin/provision base
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
- **Push-to-Talk**: Exclusive mic routing for Discord ([docs](docs/push-to-talk.md))
- **Authentication**: Optional passwordless sudo and auto-login ([docs](docs/security.md))

### Automatic Features

- **Daily Updates**: Cron runs `/usr/local/bin/provision` once a day at 06:00
- **Self-healing**: Each run reapplies configuration if drift is detected

## Project Structure

```
neonet/
├── ansible.cfg          # Ansible configuration
├── bootstrap.sh         # Initial setup script
├── Brewfile             # Homebrew packages (secoes visuais)
├── hosts                # Ansible inventory (localhost)
├── local.yml            # Main playbook
├── README.md            # This file
├── roles/
│   ├── base/            # Base system configuration (tags: base,ansible,user,cron)
│   ├── pushtotalk/      # Push-to-Talk para Discord
│   └── workstation/     # User applications (tags: homebrew,bun,macos,privacy)
├── group_vars/all       # Variables (GitHub username, etc.)
├── docs/                # Documentacao (PTT, CI, etc.)
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

### Ansible reports "no hosts to target"

The playbook targets `localhost` directly, so run it through the wrapper:

```bash
./run.sh
```

or explicitly against the local inventory:

```bash
ansible-playbook -i localhost, local.yml
```

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
ansible-playbook --syntax-check -i localhost, local.yml

# Dry run
ansible-playbook --check -i localhost, local.yml
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
- **Sudo**: Ansible runs as your user; only individual tasks escalate privileges with sudo when needed
- **Permissions**: Proper file permissions enforced

## License

MIT
