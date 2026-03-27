#!/bin/bash

LOCAL_USER=${2:-tg}
LOCAL_GROUP=$(id -gn 2>/dev/null || echo "staff")
PASSWORD_STORE_REPO=${1:-https://gitlab.com/thomas.groch/password-store.git}

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

# Set correct permissions on SSH key if it exists
if [ -f ~/.ssh/tgroch_id_rsa ]; then
    chown $LOCAL_USER:$LOCAL_GROUP ~/.ssh/tgroch_id_rsa
    chmod 600 ~/.ssh/tgroch_id_rsa
    ssh-add ~/.ssh/tgroch_id_rsa 2>/dev/null || echo "Note: Could not add SSH key to agent"
fi

# Clone password store
if [[ ! -e ~/.password-store ]]; then
    git clone "$PASSWORD_STORE_REPO" ~/.password-store
fi

# Install Homebrew if not installed on macOS
if [[ $(uname) == "Darwin" ]] && ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install pass
if ! command -v pass &> /dev/null; then
    if command -v brew &> /dev/null; then
        brew install pass
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm pass
    elif command -v apt &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y pass
    else
        echo "Unsupported package manager. Please install 'pass' manually."
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

# cat "/run/media/${LOCAL_USER}/SAFE/safe/gpg/thomas.groch@gmail.com.private.gpg-key.passphrase" | xclip -selection clipboard

# gpg --import "/run/media/${LOCAL_USER}/SAFE/safe/gpg/thomas.groch@gmail.com.private.gpg-key"
# gpg --import "/run/media/${LOCAL_USER}/SAFE/safe/gpg/thomas.groch@gmail.com.public.gpg-key"

sudo touch /var/log/ansible.log
sudo chown $USER:$LOCAL_GROUP /var/log/ansible.log

ansible-pull --url https://github.com/homeofficehost/neonet --limit localhost --checkout master
