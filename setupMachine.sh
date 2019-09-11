#!/bin/bash

echo "Setting up machine..."

if [[ $UID -ne 0 ]]; then
	sudo -p 'Restarting as root, password: ' bash $0 "$@"
	exit $?
fi

pushd ~ > /dev/null

apt-get update

if [ -f "$(which lsb_release)" ]; then
	lsb_release -a
else
	apt-get install -y lsb-release
	lsb_release -a
fi

if [ -f "$(which wget)" ]; then
	echo "(wget already installed)"
else
	echo ""
	echo "Installing wget"
	echo ""
	apt-get install -y wget
fi

if [ -f "$(which curl)" ]; then
	echo "(curl already installed)"
else
	echo ""
	echo "Installing curl"
	echo ""
	apt-get install -y curl
fi

if [ -f "$(which git)" ]; then
	echo "(git already installed)"
else
	echo ""
	echo "Installing git"
	echo ""
	apt-get install -y git
fi

if [ -f "$(which vim)" ]; then
	echo "(vim already installed)"
else
	echo ""
	echo "Installing vim"
	echo ""
	apt-get install -y vim
fi

if [ -f "$(which gvim)" ]; then
	echo "(gvim already installed)"
else
	echo ""
	echo "Installing gvim"
	echo ""
	apt-get install -y vim-gtk3
fi

if [ -f "$(which pwsh)" ]; then
	echo "(pwsh already installed)"
else
	echo ""
	echo "Installing pwsh"
	echo ""
	#wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
	#dpkg -i packages-microsoft-prod.deb
	#apt-get update
	#apt-get install -y powershell

    # This way should be a little more version-independent, and also includes the VS Code
    # IDE.
    # I can't seem to get this way to work:
    #bash <(wget -O - https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/install-powershell.sh) -includeide
    # But this does:
    wget -O - https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/install-powershell.sh | bash -s includeide
fi

# Tweak double-click word boundaries in terminal:
dconf write /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/word-char-exceptions '@ms "-#%&+,./:=?@_~"'

if [ ! -d ./nixSetup ]; then
	echo ""
	echo "Cloning personal stuff"
	echo ""
	# sudo back to the calling user so that you won't have to use sudo to do things
	# like "git pull" in this dir:
	sudo -u $SUDO_USER git clone https://github.com/jazzdelightsme/nixSetup.git
	cd ./nixSetup
	pwsh -ExecutionPolicy Bypass -NoProfile ./moreSetup.ps1

    # Reload profile in case env. vars were added.
    . ~/.profile
else
	echo ""
	echo "The nixSetup directory already exists. If you want to re-run the setup,"
	echo "do something like:"
	echo ""
	echo "   cd ~/nixSetup"
	echo "   git pull"
	echo "   sudo pwsh -ExecutionPolicy Bypass -NoProfile ./moreSetup.ps1"
	echo "   . ~/.profile"
	echo ""
fi

popd > /dev/null

