#!/bin/sh

echo "Setting up machine..."

apt-get update
apt-get install -y lsb-release wget curl git vim vim-gtk3

pushd ~
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install -y powershell

git clone https://github.com/jazzdelightsme/nixSetup.git

cd nixSetup
sudo pwsh -ExecutionPolicy Bypass ./moreSetup.ps1

popd

