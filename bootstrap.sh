#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

REPO="https://github.com/homeofficehost/neonet"
LOGFILE="$HOME/ansible_provision.log"

# Ensure ~/.ssh exists with secure permissions
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
echo "Ensured $HOME/.ssh (mode 700)"

# Validate sudo interactively; provisioning needs an administrator account
if ! sudo -v; then
    echo "This user does not have sudo privileges. Provisioning requires an administrator account." >&2
    exit 1
fi
echo "sudo privileges confirmed."

# Install package manager deps per OS (macOS → brew, Arch → pacman)
case "$(uname -s)" in
    Darwin)
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        command -v bw &> /dev/null || brew install bitwarden-cli
        command -v ansible-pull &> /dev/null || brew install ansible
        ;;
    Linux)
        if command -v pacman &> /dev/null; then
            sudo pacman -Sy --needed --noconfirm ansible git bitwarden-cli
        else
            echo "Unsupported Linux distro (expected Arch/pacman)." >&2
            exit 1
        fi
        ;;
esac

# Run ansible-pull as the current user against localhost, appending all
# output to the home log while keeping terminal output for manual runs.
: >> "$LOGFILE"
printf "\n%s bootstrap: starting ansible-pull\n" "$(date +"%Y-%m-%d %H:%M:%S")" | tee -a "$LOGFILE"
RC=0
ansible-pull -i localhost, --url "$REPO" --checkout master 2>&1 | tee -a "$LOGFILE" || RC=${PIPESTATUS[0]}
printf "%s bootstrap: ansible-pull finished with exit code %d\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$RC" | tee -a "$LOGFILE"
exit "$RC"
