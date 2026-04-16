#!/bin/bash

LOCAL_USER=${2:-tg}
LOCAL_GROUP=$(id -gn 2>/dev/null || echo "staff")
GITHUB_REPO=${1:-https://github.com/homeofficehost/neonet}

# Check if sudo is installed and the user has sudo privileges
if sudo -v &>/dev/null; then
    echo "User has sudo privileges"
else
    echo "sudo is not installed or user does not have sudo privileges"
fi

# Ensure .ssh directory exists with correct permissions
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chown $LOCAL_USER:$LOCAL_GROUP ~/.ssh
    chmod 700 ~/.ssh
    echo "Created ~/.ssh directory"
fi

# Install Homebrew if not installed on macOS
if [[ $(uname) == "Darwin" ]] && ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Bitwarden CLI
if ! command -v bw &> /dev/null; then
    if command -v brew &> /dev/null; then
        brew install bitwarden-cli
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm bitwarden-cli
    elif command -v apt &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y bitwarden-cli
    else
        echo "Unsupported package manager. Please install 'bitwarden-cli' manually."
    fi
fi

# Install Ansible
if ! command -v ansible-pull &> /dev/null; then
    if [[ $(uname) == "Darwin" ]] && command -v brew &> /dev/null; then
        brew install ansible
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm ansible
    elif command -v apt &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y ansible
    else
        echo "Unsupported package manager. Please install 'ansible' manually."
    fi
fi

# Update system
if command -v brew &> /dev/null; then
    echo "Updating Homebrew..."
    brew update
    brew upgrade
    brew cleanup
elif command -v pacman &> /dev/null; then
    sudo sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 50/g" /etc/pacman.conf
    sudo sed -i "s/#Color/Color/g" /etc/pacman.conf
    sudo pacman -Syyu --noconfirm
elif command -v apt &> /dev/null; then
    sudo apt-get update
    sudo apt-get upgrade -y
fi

sudo touch /var/log/ansible.log
sudo chown $USER:$LOCAL_GROUP /var/log/ansible.log

ansible-pull -i hosts --url "$GITHUB_REPO" --limit "$(hostname -s).local" --checkout master
