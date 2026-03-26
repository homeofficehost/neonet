# dotfiles

Configuration and automation for tgworkstation (macOS 14 Sonoma).

## Quick Setup

```sh
curl -Lks https://github.com/homeofficehost/dotfiles/bootstrap.sh | /bin/bash
```

## What's Included

- **Ansible** pull-based orchestration via cron (user: velociraptor)
- **Homebrew** package management via Brewfile
- **Dotfiles** managed via bare git repo

## Usage

Run ansible-pull manually:
```sh
ansible-pull --vault-password-file ~/.vault_key --url https://github.com/homeofficehost/dotfiles --limit tgworkstation.local
```

Or wait for cron (set up by ansible on first run).

## License

MIT
