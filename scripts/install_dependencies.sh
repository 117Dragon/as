#!/bin/bash

# Install OVPN Access Server
sudo timedatectl set-timezone Europe/Moscow
sudo apt update
sudo apt install -y mc zip unzip ncdu wget gnupg fail2ban net-tools apt-transport-https ca-certificates
sudo mkdir -p /etc/apt/keyrings && sudo curl -fsSL https://packages.openvpn.net/as-repo-public.asc | sudo tee /etc/apt/keyrings/as-repository.asc
sudo echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/as-repository.asc] http://packages.openvpn.net/as/debian jammy main" | sudo tee /etc/apt/sources.list.d/openvpn-as-repo.list
sudo apt update && sudo apt -y install openvpn-as
sudo bash /tmp/as/scripts/deploy.sh
