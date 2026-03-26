#!/usr/bin/env bash

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Not running on Linux. Aborting!"
  exit 1
fi

get_distribution() {
	lsb_dist=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_dist"
}
distro=$( get_distribution )
distro="$(echo "$distro" | tr '[:upper:]' '[:lower:]')"
if  [ "$distro" != "ubuntu" ] && [ "$distro" != "debian" ] && [ "$distro" != "arch" ] && [ "$distro" != "manjaro" ]; then 
    echo 'Sorry, the distro you are using is not supported by this script'
    # exit 1;
fi	

source ./lib_sh/echos.sh
source ./lib_sh/requirers.sh

bot "Hi! I'm going to install tooling and tweak your system settings."

# curl -LO larbs.xyz/larbs.sh
# sudo bash larbs.sh

# bot "TTS (text-to-speech) voices"
# read -t 7 -r -p "Would you like to install voices? (y|N) [or wait 7 seconds for default=N] " response; echo ;
# response=${response:-N}
# if [[ $response =~ (yes|y|Y) ]];then
#   npx --quiet voices -m
#   ok
# fi

[[ ! -e ~/.oh-my-zsh ]] || git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh && \
	chsh -s $(which zsh)

# 2. Optionally, backup your existing ~/.zshrc file:
# cp ~/.zshrc ~/.zshrc.orig

# 3. Create a new zsh configuration file
# You can create a new zsh config file by copying the template that we have included for you.
# cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# 4. Change your default shell
# chsh -s $(which zsh)

# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# running "Installing zsh custom plugins"
# mkdir -p $ZSH_CUSTOM/plugins/

# if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
#   git clone https://github.com/supercrabtree/k.git "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
# fi

# if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
#   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
# fi

# if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
#   git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
# fi

# if [[ ! -d "${ZSH_CUSTOM}/themes/powerlevel9k" ]]; then
#   git clone https://github.com/bhilburn/powerlevel9k.git "${ZSH_CUSTOM}/themes/powerlevel9k"
# fi
# ok

# bot "Installing vim plugins"
# vim +PluginInstall +qall ## > /dev/null 2>&1
# ok

###############################################################################
bot "Developer default settings"
###############################################################################
[[ ! -e $HOME/.password-store ]] || git clone "${PASSWORD_STORE_REMOTE_URL}.git" $HOME/.password-store
# netlify --telemetry-disable
# Installation of is.sh. A fancy alternative for old good test command.
# yarn global add carbon-now-cli
# yarn global add is.sh
touch $HOME/.hushlogin
mkdir -p $MY_TEMP

mkdir -p $HOME/pi/.bin/

# Fix mariadb start bug
# mkdir -p /usr/local/etc/my.cnf.d

# Disable docker Crash Reporting
# touch ~/.docker/machine/no-error-report

###############################################################################
bot "Developer workspace"
###############################################################################

# if [[ ! -e $HOME/.password-store ]]; then
# bot "Tip: Use gpg-suite to {manage,generate,import} GPG easy there."

#   read -t 7 -r -p "Would you like to setup gpg keys? (y|N) [or wait 7 seconds for default=N] " response; echo ;
#   response=${response:-N}
#   if [[ $response =~ (yes|y|Y) ]];then
#     # Setup create/restore keys
#     password-store-installer
#   fi
# fi

# git config --global credential.helper osxkeychain

# running "Adding nightly cron software updates"
# crontab ~/.crontab

# running "Updating composer keys public keys"
# releases_key=$(curl -Ls https://composer.github.io/releases.pub)
# snapshots_key="$(curl -Ls https://composer.github.io/snapshots.pub)"
# expect << EOF
#   spawn composer self-update --update-keys
#   sleep 1
#   expect "Enter Dev / Snapshot Public Key (including lines with -----):"
#   send -- "$releases_key"
#   send "\r"
#   expect "Enter Tags Public Key (including lines with -----):"
#   send -- "${snapshots_key}\r"
#   send "\r"
#   expect eof
# EOF
# ok

running "Create dev folder in home directory"
mkdir -p ~/dev;ok

running "Create blog folder in home directory"
mkdir -p ~/blog;ok

running "Create logs folder in home directory"
mkdir -p ~/logs;ok

if  [ "$distro" == "ubuntu" ]; then
	sudo apt-get -y install build-essential curl file git
elif [ "$distro" == "debian" ]; then
	sudo yum -y groupinstall 'Development Tools'
	sudo yum -y install curl file git
	sudo yum -y install libxcrypt-compat # needed by Fedora 30 and up
elif [ "$distro" == "arch" ]  || [ "$distro" == "manjaro" ]; then
	sudo pacman -Sy # prevent fail on fist boot because no pacman database files
	sudo pacman -S build-essential curl file git
  sudo pacman -S base-devel
fi
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile

bot "Configuring brew global packages"
response_retry_install=y
while [[ $response_retry_install =~ (yes|y|Y) ]]; do
    running "installing brew bundle..."
    brew bundle --verbose;ok

    running "checking brew bundle..."
    brew bundle check >& /dev/null
    if [ $? -eq 0 ]; then
      response_retry_install=N
      ok "Full brew bundle successfully installed."
    else
      warn "brew bundle check exited with error code"
      bot "Often some programs are not installed."
      read -t 7 -r -p "Would you like to try again brew bundle? (y|N) [or wait 7 seconds for default=y]" response_retry_install; echo ;
      response_retry_install=${response_retry_install:-Y}
    fi
done


###############################################################################
bot "The End"
###############################################################################
# npx --quiet okimdone
bot "Woot! All done."
sleep 2

###############################################################################
# Kill affected applications                                                  #
###############################################################################
bot "Done. Note that some of these changes require a logout/restart to take effect. I will kill affected applications (so they can reboot)...."

read -n 1 -s -r -p "Press any key to continue"
