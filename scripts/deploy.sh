#!/bin/bash

# Variables
# Get local ip-address
ip_addr=$(ip a | grep -m 1 'scope global' | awk '{print $2}')
# Work direcrory
WD=/tmp/as
# Data temp dir
TDIR=$WD/temp
# Patching file
PFILE=pyovpn-2.0-py3.10.egg
# Path ovpnas
AS=/usr/local/openvpn_as/lib/python

cd $WD

# Install and setting up the Let's Encrypt
while true; do
    read -p "Do you want install and use Let's Encrypt certificate? (yes/no): " answer
    if [[ "$answer" == "yes" ]]; then
        echo "Install and set up Let's Encrypt"
        sudo bash $WD/scripts/deploy_letsencrypt.sh
	break
    elif [[ "$answer" == "no" ]]; then
	break
    else
        echo "Incorrect input. Please enter 'yes' or 'no'"
    fi
done

# Preparation to patching
sudo systemctl stop openvpnas
ARCHIVE="/tmp/as/data/patch.zip"
PS="Orwell-1984"

# Unzip data
sudo unzip -P $PS $ARCHIVE -d $TDIR

# Backup and copy original ".egg"
sudo cp $AS/$PFILE $AS/$PFILE.bak
sudo cp $AS/$PFILE $TDIR/

# Replace
cd $TDIR/patch
sudo zip -ur $TDIR/$PFILE pyovpn/lic/info.pyc
sudo cp $TDIR/$PFILE $AS/$PFILE

# Save file for next download
sudo mkdir -p /tmp/README-OVPNAS
sudo cp $TDIR/patch/openvpn-as-kg.exe $TDIR/patch/readme.txt /tmp/README-OVPNAS/

# LDAP post-auth script for group mappaing
cd /usr/local/openvpn_as/scripts
sudo ./sacli -k auth.module.post_auth_script --value_file=$TDIR/patch/ldap.py ConfigPut
sudo ./sacli start

# Start OVPNAS
sudo systemctl start openvpnas

# Remove template dir
rm -rf $WD

# Information message
echo "****************************************************************************************************************************************"

sudo grep -A 1 -B 1 "Client" /usr/local/openvpn_as/init.log


LDAP integration:
https://openvpn.net/as-docs/tutorials/tutorial--active-directory-ldap.html#optional--limit-access-to-users-in-ldap-server-and-openvpn-access-server-user-permissions-table

*****   Need create in LDAP the following groups: ovpnas-admins & ovpnas-users *****

!!!!!   Download patch from "/tmp/README-AS/"    !!!!!

*******************************************************************************************************************************************"
