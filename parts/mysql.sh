#!/bin/bash

# Run loop until MySQL user has been authenticated
until [ ! -z "$MYSQLUSER" ] && [ ! -z "$MYSQLPASSWORD" ]; do
	
  # Prompt for MySQL user
  read -e -p "MySQL admin user: " -i "$MYSQLUSER" DBUSER
	
  # Prompt for MySQL password
  read -e -s -p "MySQL password: " -i "$MYSQLPASSWORD" DBPASSWD
  
	# Try to log in to MySQL with the supplied details
	CONNECTION=$(mysql -u $DBUSER --password=$DBPASSWD -e "SELECT User FROM mysql.user WHERE Host = 'localhost';"|grep "$SITEOWNER")
	if [ "$CONNECTION" = "$SITEOWNER" ] || [ "$CONNECTION" = "" ]; then
	
	# Successful login to MySQL server - set variables
		read -e -p "MySQL database name: " DBNAME

		MYSQLUSER=$DBUSER
		MYSQLPASSWORD=$DBPASSWD

		# Log in to MySQL properly and create the new user and database
		NEWDB=$(mysql -u $MYSQLUSER -p$MYSQLPASSWORD -e "CREATE DATABASE IF NOT EXISTS $DBNAME")
		if [ ! -z "$NEWDB" ]; then
			# There was terminal output - this is an error as there shouldn't be output
			printf "$GENERALERROR"
			exit;
		fi
		if [ "$CONNECTION" = "" ]; then
			# If user wasn't found in earlier query, create user and grant privileges
			NEWUSERPASSWD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20)
			GRANT=$(mysql -u $MYSQLUSER -p$MYSQLPASSWORD -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$SITEOWNER'@'localhost' IDENTIFIED BY '$NEWUSERPASSWD'")
		else
			# If user was found, grant privileges
			GRANT=$(mysql -u $MYSQLUSER -p$MYSQLPASSWORD -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$SITEOWNER'@'localhost'")
			if [ ! -z "$GRANT" ]; then
				printf "$GENERALERROR"
				exit;
			fi
		fi
	elif [ ${CONNECTION:0:10} = "ERROR 1045" ]; then
		# User not authenticated
		printf "Error: MySQL credentials rejected.\n"
	else
		# Something happened that I've not accounted for
		printf "$GENERALERROR"
		exit;
	fi
done