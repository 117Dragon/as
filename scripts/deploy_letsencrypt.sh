#!/bin/bash

## Variables discription
# $1=/etc/letsencrypt/archive
# $2=$DOMAIN
# $3=privkey.pem                # last modified file
# $4=cert.pem                   # last modified file
# $5=fullchain.pem              # last modified file

# Let's Encrypt path
LPATH=/etc/letsencrypt/archive

# Work direcrory
WD=/tmp/as

# Install Let's Encrypt
sudo apt install -y certbot

# Create certificates
echo "*************************************************************************
*************************************************************************
****  Don't forget to open or redirect port 80 for the OpenVPN Server  **
*************************************************************************
*************************************************************************"

echo "Enter domain for create a certificate"
read DOMAIN
echo "Enter your e-mail for renewal and security notices"
read EMAIL
certbot certonly --agree-tos --noninteractive --standalone --email $EMAIL --preferred-challenges http -d $DOMAIN

# Set variables latest generated Let's Encrypt certificates
LPK=$(sudo find $LPATH/$DOMAIN -type f | grep "privkey" | sudo xargs ls -t | head -n 1 | awk -F/ '{print $NF}')
LCRT=$(sudo find $LPATH/$DOMAIN -type f | grep "cert" | sudo xargs ls -t | head -n 1 | awk -F/ '{print $NF}')
LCHN=$(sudo find $LPATH/$DOMAIN -type f | grep "chain" | sudo xargs ls -t | head -n 1 | awk -F/ '{print $NF}')

# Set OPVNAS https certificate
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "$LPATH/$DOMAIN/$LPK" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "$LPATH/$DOMAIN/$LCRT" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.ca_bundle" --value_file  "$LPATH/$DOMAIN/$LCHN" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli start

# Install and setting up the Let's Encrypt
while true; do
    read -p "Do you want install and use Nginx reverse Proxy? (yes/no): " answer
    if [[ "$answer" == "yes" ]]; then
        echo "Install and set up Nginx"
        sudo bash $WD/scripts/deploy_nginx.sh $LPATH $DOMAIN $LPK $LCRT $LCHN
	sudo bash $WD/scripts/certbotrenew_nginx.sh $LPATH $DOMAIN $LPK $LCRT $LCHN
	break
    elif [[ "$answer" == "no" ]]; then
	sudo bash $WD/script/certbotrenew.sh $LPATH $DOMAIN $LPK $LCRT $LCHN
	break
    else
        echo "Incorrect input. Please enter 'yes' or 'no'"
    fi
done

# Make file exec
sudo chmod +x /usr/local/sbin/certbotrenew_ovpnas.sh

# Make crontab
sudo echo "0 4 1 * * root /usr/local/sbin/certbotrenew_ovpn.sh" >> /etc/crontab
