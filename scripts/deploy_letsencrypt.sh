#!/bin/bash

# Variables
# Let's Encrypt path
LPATH=/etc/letsencrypt/archive

# Install Let's Encrypt
sudo apt install -y certbot

# Create certificates
echo "*************************************************************************



****  Don't forget to open or redirect port 80 for the OpenVPN Server  **



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

# Make script for cron
sudo cat <<EOF >>/usr/local/sbin/certbotrenew_ovpnas.sh
#!/bin/bash

# Variables
LPK=$(sudo find $LPATH/$DOMAIN -type f | grep "privkey" | sudo xargs ls -t | head -n 1 | awk -F/ '{print $NF}')
LCRT=$(sudo find $LPATH/$DOMAIN -type f | grep "cert" | sudo xargs ls -t | head -n 1 | awk -F/ '{print $NF}')
LCHN=$(sudo find $LPATH/$DOMAIN -type f | grep "chain" | sudo xargs ls -t | head -n 1 | awk -F/ '{print $NF}')

# Renew Let's Encrypt certificate
certbot renew --renew-by-default
sleep 15

# Setup new certificate to OVPNAS
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "$LPATH/$DOMAIN/$LPK" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "$LPATH/$DOMAIN/$LCRT" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.ca_bundle" --value_file  "$LPATH/$DOMAIN/$LCHN" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli start

EOF

# Make file exec
sudo chmod +x /usr/local/sbin/certbotrenew_ovpnas.sh

# Make crontab
sudo echo "0 4 1 * * root /usr/local/sbin/certbotrenew_ovpn.sh" >> /etc/crontab
