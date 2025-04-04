#!/bin/bash

# Set variables
# Get local ip-address
ip_addr=$(ip a | grep -m 1 'scope global' | awk '{print $2}')
# Work direcrory
WD=/tmp/as
# Data temp dir
TDIR=/tmp/as/temp
# Unzip data dir
UDIR=/tmp/as/temp/data_zip
# Patching file
PFILE=pyovpn-2.0-py3.10.egg
# Let's Encrypt path
LPATH=/etc/letsencrypt/archive
# Path ovpnas
AS=/usr/local/openvpn_as/lib/python

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
certbot certonly --standalone --email $EMAIL --preferred-challenges http -d $DOMAIN

# Set variables latest generated Let's Encrypt certificates
LPK=$(sudo find $LPATH/$DOMAIN -type f | grep "privkey" | sudo xargs ls -t | head -n 1 | awk -F/ '{print $NF}')
LCRT=$(sudo find $LPATH/$DOMAIN -type f | grep "cert" | sudo xargs ls -t | head -n 1 | awk -F/ '{print $NF}')
LCHN=$(sudo find $LPATH/$DOMAIN -type f | grep "chain" | sudo xargs ls -t | head -n 1 | awk -F/ '{print $NF}')

# Preparation to patching
sudo systemctl stop openvpnas
ARCHIVE="/tmp/as/data/data.zip"
PS="Orwell-1984"
# Unzip data (UDIR=data_zip)
sudo unzip -P $PS $ARCHIVE -d $TDIR
# Backup and copy original ".egg"
sudo cp $AS/$PFILE $AS/$PFILE.bak
sudo cp $AS/$PFILE $UDIR/patch

# Make directory for nginx SSL
sudo mkdir -p /etc/nginx/ssl/$DOMAIN

# Make certificate for nginx
sudo cat $LPATH/$DOMAIN/$LCRT $LPATH/$DOMAIN/$LCHN > /etc/nginx/ssl/$DOMAIN/"$DOMAIN"_fullchain.pem
#sudo mv $LPATH/$DOMAIN/"$DOMAIN"_fullchain.pem /etc/nginx/ssl/$DOMAIN/
sudo cp $LPATH/$DOMAIN/$LPK /etc/nginx/ssl/$DOMAIN/

# Replace domain in nginx configs
sudo sed -i 's/example.com/'$DOMAIN'/g' $UDIR/nginx/crt.conf $UDIR/nginx/vhost.conf

# Add symlink and remove default vHost
sudo cp $UDIR/nginx/crt.conf /etc/nginx/ssl/$DOMAIN/
sudo cp $UDIR/nginx/proxy.conf $UDIR/nginx/ssl.conf /etc/nginx/conf.d/
sudo cp $UDIR/nginx/vhost.conf /etc/nginx/sites-available/$DOMAIN

# Add symlink and remove default vHost
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl start nginx

# Replace
cd $UDIR/patch
sudo zip -ur $PFILE pyovpn/lic/info.pyc
sudo cp $PFILE $AS/$PFILE

# Save file for next download
sudo mkdir -p /tmp/README-OVPNAS
sudo cp $UDIR/patch/openvpn-as-kg.exe $UDIR/patch/readme.txt /tmp/README-OVPNAS/

# Start OVPNAS
sudo systemctl start openvpnas

# Set OPVNAS https certificate
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "$LPATH/$DOMAIN/$LPK" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "$LPATH/$DOMAIN/$LCRT" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.ca_bundle" --value_file  "$LPATH/$DOMAIN/$LCHN" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli start

# Make script for install
sudo cat <<EOF >>/usr/local/sbin/certbotrenew.sh
#!/bin/bash

# Renew Let's Encrypt certificate
certbot renew --renew-by-default
sleep 30

# Setup new certificate to OVPNAS
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "$LPATH/$DOMAIN/$LPK" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "$LPATH/$DOMAIN/$LCRT" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.ca_bundle" --value_file  "$LPATH/$DOMAIN/$LCHN" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli start

# Backup and setup new certificate to nginx
DATE=$(date +%Y%m%d)
sudo mkdir -p /etc/nginx/ssl/temp/$DOMAIN-$DATE
sudo mv /etc/nginx/ssl/$DOMAIN/* /etc/nginx/ssl/temp/$DOMAIN-$DATE
sudo cat $LPATH/$DOMAIN/$LCRT $LPATH/$DOMAIN/$LCHN > /etc/nginx/ssl/$DOMAIN/"$DOMAIN"_fullchain.pem
sudo cp $LPATH/$DOMAIN/$LPK /etc/nginx/ssl/$DOMAIN/
sudo systemctl restart nginx

EOF

# Make file exec
sudo chmod +x /usr/local/sbin/certbotrenew.sh

# Exec script
#sudo bash /usr/local/sbin/certbotrenew.sh

# Make crontab
sudo echo "0 4 1 * * root /usr/local/sbin/certbotrenew.sh" >> /etc/crontab

# Remove template dir
#rm -rf $WD

# Information message
echo "*******************************************************************************************************************************"
sudo grep -A 1 -B 1 "Client" /usr/local/openvpn_as/init.log
echo "*********************************************************************************************************************************
****  !!!!!  Auth on https://$ip_addr:943/admin  ********************************************************************************
****  !!!!!  Be sure to replace the value with your own (domain):  **************************************************************
****  !!!!!  Admin  UI - Network Setting - Hostname to your previously specified domain:   **************************************
*********************************************************************************************************************************
*********************************************************************************************************************************
****  !!!!!  Download patch from "/tmp/README-AS/"  *****************************************************************************
*********************************************************************************************************************************"
