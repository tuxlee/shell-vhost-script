#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root or with sudo privileges."
  exit 1
fi

set -e

echo "# What is the site domain?"
read MY_DOMAIN

echo "# What is user?"
read SITE_USER

echo "# Creating the Directory Structure"
sudo mkdir -p /home/$SITE_USER/www/$MY_DOMAIN/public

echo "# Granting Permissions"

sudo chmod 755 /home/$SITE_USER
sudo chown -R $SITE_USER:$SITE_USER /home/$SITE_USER/www/$MY_DOMAIN/public
sudo chown -R $SITE_USER:$SITE_USER /home/$SITE_USER/www/$MY_DOMAIN
sudo chmod -R 755 /home/$SITE_USER/www

echo "# Creating demo page"
cat <<EOF >/home/$SITE_USER/www/$MY_DOMAIN/public/index.php
<html>
  <head>
    <title>Welcome to $MY_DOMAIN!</title>
  </head>
  <body>
    <h1>Success! The $MY_DOMAIN virtual host is working!</h1>
  </body>
</html>
EOF

sudo chown -R $SITE_USER:$SITE_USER /home/$SITE_USER/www/$MY_DOMAIN/public/index.php
sudo chmod -R 755 /home/$SITE_USER/www/$MY_DOMAIN/public/index.php

echo "# Creating Virtual Host File"
cat <<EOF >/etc/apache2/sites-available/$MY_DOMAIN.conf
<VirtualHost *:80>
    ServerAdmin admin@$MY_DOMAIN
    ServerName $MY_DOMAIN
    ServerAlias www.$MY_DOMAIN
    DocumentRoot /home/$SITE_USER/www/$MY_DOMAIN/public
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory /home/$SITE_USER/www/$MY_DOMAIN/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

echo "# Enabling the New Virtual Host File"
sudo a2ensite $MY_DOMAIN.conf

echo "# Restarting Apache"
sudo systemctl restart apache2

if sestatus | grep "SELinux status" | grep -q "enabled"; then
    echo "# Setting SELinux context for the site directory"
    sudo chcon -R -t httpd_sys_content_t /home/$SITE_USER/www/$MY_DOMAIN/public
    sudo setsebool -P httpd_can_network_connect 1
fi

while true; do
    read -p "Do you wish to set up local hosts file (Optional)? " yn
    case $yn in
        [Yy]* ) echo "127.0.0.1       $MY_DOMAIN" | sudo tee -a /etc/hosts; break;;
        [Nn]* ) break;;
        * ) echo "Please answer Y or N.";;
    esac
done

while true; do
    read -p "Do you want to set up a new MariaDB database and user? (Y/N) " yn
    case $yn in
        [Yy]* ) 
            echo "# What is the database name?"
            read DB_NAME

            echo "# What is the MariaDB username?"
            read DB_USER

            echo "# What is the password for the new MariaDB user?"
            read -s DB_PASS

            echo "# Creating MariaDB database and user"
            sudo mysql -e "CREATE DATABASE $DB_NAME;"
            sudo mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"

            echo "###"
            echo "# Database '$DB_NAME' and user '$DB_USER' created with all permissions."
            echo "###"
            break;;
        [Nn]* ) 
            echo "###"
            echo "# Skipping database setup."
            echo "###"
            break;;
        * ) echo "Please answer Y or N.";;
    esac
done

echo "###"
echo "# All done! Check your new virtual host: http://$MY_DOMAIN"
echo "###"
exit
