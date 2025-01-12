#!/bin/bash

echo "### Pterodactyl Installer By: mark69lol ###"
echo "Pterodactyl Wings Installation Script"

echo "Updating system..."
apt update -y && apt upgrade -y

echo "Installing service"
apt-get install sysvinit-utils -y

echo "Installing wings"
sudo mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
sudo chmod u+x /usr/local/bin/wings
