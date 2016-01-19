#!/bin/bash

# This should return the directory the current script is running from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include file of user-configurable variables
source $DIR/variables.cfg

GENERALERROR="Something unexpected happened. This script is unable to finish. Please make a note of any error output and report."

# Switch to the directory in which the website folders will be created
cd $WEBROOTFOLDER

# Run loop until an FQDN without a current folder is entered
until [ ! -z "$SITENAME" ]; do
	# Prompt for website FQDN
	read -e -p "Site FQDN, e.g. domain.com, or sub.domain.com: " FQDN

	if [ ! -d "$FQDN" ]; then 
		SITENAME=$FQDN
	else
		# A folder for that FQDN already exists - loop restarts
		printf "Error: that site already exists. You will need to use another FQDN to continue.\n"
	fi
done

read -e -p "Which user should own this directory? e.g. $USER: " SITEOWNER

USER=$(getent passwd $SITEOWNER)
if [ -z "$USER" ]; then
    PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8)
    CRYPTED=$(openssl passwd -crypt $PASS)
    useradd -m $SITEOWNER --password $CRYPTED
fi

source $DIR/parts/mysql.sh

# Create the folder for the website
mkdir $SITENAME
printf "Created directory for website in $WEBROOTFOLDER$SITENAME\n"

# Switch to the new directory
cd $SITENAME

# Make the necessary folders in the new website's folder
mkdir backups public logs private

# Copy a basic index.html folder to the web root on the new site
cp ${DIR}/index.html $WEBROOTFOLDER${SITENAME}/public/
cp ${DIR}/404.html $WEBROOTFOLDER${SITENAME}/public/
if [ ! -z "$NEWUSERPASSWD" ]; then
	echo $NEWUSERPASSWD > $WEBROOTFOLDER${SITENAME}/private/mysql.txt
fi

if [ ! -z "$PASS" ]; then 
    echo $PASS > $WEBROOTFOLDER${SITENAME}/private/login.txt
fi

# Set permissions
chown -R $SITEOWNER:$SITEOWNER $WEBROOTFOLDER$SITENAME
if [ -e "$WEBROOTFOLDER${SITENAME}/private/mysql.txt" ]; then
	chmod 600 $WEBROOTFOLDER${SITENAME}/private/*.txt
fi

# Create Nginx configuration file for the new site
cp ${DIR}/template.conf ${NGINXCONFIG}sites-available/$SITENAME.conf
sed -i "s/FQDN/$SITENAME/g" ${NGINXCONFIG}sites-available/$SITENAME.conf
sed -i "s|WEBROOTFOLDER|$WEBROOTFOLDER|g" ${NGINXCONFIG}sites-available/$SITENAME.conf
sed -i "s/FQDN/$SITENAME/g" $WEBROOTFOLDER${SITENAME}/public/index.html
ln -s ${NGINXCONFIG}sites-available/$SITENAME.conf ${NGINXCONFIG}sites-enabled
printf "Set up basic Nginx configuration file to /etc/nginx/sites-available\n"
service nginx reload

if [ ! -z "$PASS" ]; then
    printf "New user can log in with the password $PASS"
fi

printf "\n"