#!/bin/bash

# Make certbot renew script and set crontab

## Variables discription
# $1=/etc/letsencrypt/archive
# $2=$DOMAIN
# $3=privkey.pem		# last modified file
# $4=cert.pem			# last modified file
# $5=fullchain.pem		# last modified file

sudo cat <<EOF >>/usr/local/sbin/certbotrenew_ovpnas.sh

#!/bin/bash

# Renew Let's Encrypt certificate
certbot renew --renew-by-default
sleep 30

# Setup new certificate to OVPNAS
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.priv_key" --value_file "$1/$2/$3" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.cert" --value_file "$1/$2/$4" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "cs.ca_bundle" --value_file "$1/$2/$5" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli start

# Backup and setup new certificate to nginx
DATE=$(date +%Y%m%d)
sudo mkdir -p /etc/nginx/ssl/temp/$2-$DATE
sudo mv /etc/nginx/ssl/$2/* /etc/nginx/ssl/temp/$2-$DATE
sudo cat $1/$2/$4 $1/$2/$5 > /etc/nginx/ssl/$2/"$2"_fullchain.pem
sudo cp $1/$2/$3 /etc/nginx/ssl/$2/privkey.pem
sudo systemctl restart nginx

EOF
