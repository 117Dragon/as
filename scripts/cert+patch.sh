#!/bin/bash

# Variables
# Get local ip-address
ip_addr=$(ip a | grep -m 1 'scope global' | awk '{print $2}')
# Work files
WF=/tmp/as/
# path ovpnas
AS=/usr/local/openvpn_as/lib/python/
# Patch dir
PDIR=/tmp/
# Unzip dir
UDIR=/tmp/data_zip/
# Patching file
PFILE=pyovpn-2.0-py3.10.egg
# Let's Encrypt path
LPATH=/etc/letsencrypt/archive/

# Create certificates
echo "*************************************************************************
*************************************************************************
****  Don't forget to open or redirect port 80 for the OpenVPN Server  **
*************************************************************************
*************************************************************************"
sleep 10

echo "Enter domain for create a certificate"
read DOMAIN
echo "Enter your e-mail for renewal and security notices"
read EMAIL
certbot certonly --standalone --email $EMAIL --preferred-challenges http -d $DOMAIN
sleep 5

# Preparation to patching
sudo systemctl stop openvpnas
ARCHIVE="tmp/as/data/data.zip"
PS="Orwell-1984"
unzip -P $PS $ARCHIVE -d $TDIR
sudo cp $AS$PFILE $TDIR
unzip $TDIR$PFILE -d "$UDIR"py

## Preparation the nginx for SSL
# Make directory for SSL
sudo mkdir -p /etc/nginx/ssl/$DOMAIN

# Make certificate for nginx
sudo cat $LPATH$DOMAIN/cert1.pem $LPATH$DOMAIN/fullchain1.pem > $LPATH$DOMAIN/fullchain_nginx.pem
sudo mv $LPATH$DOMAIN/fullchain_nginx.pem /etc/nginx/ssl/$DOMAIN/
sudo cp $LPATH$DOMAIN/privkey1.pem /etc/nginx/ssl/$DOMAIN/

# Replace domain in nginx configs
sed -i 's/example.com/'$DOMAIN'/g' "$UDIR"nginx/crt.conf "$UDIR"nginx/vhost.conf

# Add symlink and remove default vHost
sudo cp "$UDIR"nginx/crt.conf /etc/nginx/ssl/$DOMAIN/
sudo cp "$UDIR"nginx/proxy.conf /etc/nginx/conf.d/
sudo cp "$UDIR"nginx/ssl.conf /etc/nginx/conf.d/
sudo cp "$UDIR"nginx/vhost.conf /etc/nginx/sites-available/$DOMAIN/
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl start nginx

# Add symlink and remove default vHost
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl start nginx

# Replace
cp "$UDIR"patch/info.pyc "UDIR"py/pyovpn/lic/info.pyc

# Make .egg and patching
zip -r "$UDIR"$PFILE "$UDIR"py/*
sudo cp "$UDIR"$PFILE "$AS"$PFILE

# Save file for next download
sudo mkdir -p /tmp/README-AS
sudo cp "$UDIR"openvpn-as-kg.exe "$UDIR"readme.txt /tmp/README-AS/

# Make script for install
#!/bin/bash
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "/etc/letsencrypt/live/$DOMAIN/cert.pem" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.ca_bundle" --value_file "/etc/letsencrypt/live/$DOMAIN/chain.pem" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli start
EOL
sleep 3

# Make file exec
sudo chmod +x /usr/local/sbin/certbotrenew.sh

# Exec script
sudo bash /usr/local/sbin/certbotrenew.sh

# Make crontab
sudo echo "0 8 1 * * /usr/local/sbin/certbotrenew.sh" >> /etc/crontab

# Start OVPNAS
sudo systemctl start openvpnas

# Remove template dir
#rm -rf $UDIR $WF

# Information message
echo "*******************************************************************************************************************************"
sudo grep -A 1 -B 1 "Client" /usr/local/openvpn_as/init.log\n
echo "*********************************************************************************************************************************
****  !!!!!  Auth on https://$ip_addr:943/admin  ********************************************************************************
****  !!!!!  Be sure to replace the value with your own (domain):  **************************************************************
****  !!!!!  Admin  UI - Network Setting - Hostname to your previously specified domain:   **************************************
*********************************************************************************************************************************
*********************************************************************************************************************************
****  !!!!!  Download patch from "/tmp/patch"  **********************************************************************************
*********************************************************************************************************************************"
