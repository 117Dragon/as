#!/bin/bash

# $1=/etc/letsencrypt/archive
# $2=$DOMAIN
# $3=privkey.pem                # last modified file
# $4=cert.pem                   # last modified file
# $5=fullchain.pem              # last modified file

# Variables
NDIR=data/nginx

# Work direcrory
WD=/tmp/as

# Install applications
sudo apt install -y nginx
sudo systemctl stop nginx

# Make directory for nginx SSL
sudo mkdir -p /etc/nginx/ssl/$2

# Make certificate for nginx
sudo cat $1/$2/$4 $1/$2/$5 > /etc/nginx/ssl/$2/"$2"_fullchain.pem
sudo cp $1/$2/$3 /etc/nginx/ssl/$2/privkey.pem

# Replace domain in nginx configs
sudo sed -i 's/example.com/'$2'/g' $NDIR/crt.conf $NDIR/vhost.conf

# Add symlink and remove default vHost
sudo cp $NDIR/crt.conf /etc/nginx/ssl/$2/
sudo cp $NDIR/proxy.conf $NDIR/ssl.conf /etc/nginx/conf.d/
sudo cp $NDIR/vhost.conf /etc/nginx/sites-available/$2.conf

# Add symlink and remove default vHost
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/$2.conf /etc/nginx/sites-enabled/
sudo systemctl start nginx

