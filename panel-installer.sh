#!/bin/bash

echo "### Pterodactyl Installer By: mark69lol ###"
echo "Pterodactyl Panel Installation Script"
echo "Please provide the following information:"

read -p "Enter the server IP (default 127.0.0.1): " SERVER_IP
read -p "Enter the server port (default 8080): " SERVER_PORT
SERVER_IP=${SERVER_IP:-127.0.0.1}
SERVER_PORT=${SERVER_PORT:-8080}
read -p "Enter the MySQL host: " MYSQL_HOST
read -p "Enter the MySQL username: " MYSQL_USER
read -p "Enter the MySQL password: " MYSQL_PASSWORD
read -p "Enter the MySQL database name: " MYSQL_DATABASE

echo "Updating system..."
apt update -y && apt upgrade -y

echo "Installing service"
apt-get install sysvinit-utils -y

echo "Installing dependencies..."
apt install -y apache2 php php-cli php-mysql php-gd php-xml php-mbstring php-curl git curl unzip sudo python3 python3-pip

echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

echo "Downloading Pterodactyl Panel..."
cd /var/www
git clone https://github.com/pterodactyl/panel.git pterodactyl
cd pterodactyl

echo "Configuring MySQL Database..."
cp .env.example .env
sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env 
sed -i "s/DB_HOST=.*/DB_HOST=$MYSQL_HOST/" .env 
sed -i "s/DB_PORT=.*/DB_PORT=3306/" .env 
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$MYSQL_DATABASE/" .env 
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$MYSQL_USER/" .env 
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$MYSQL_PASSWORD/" .env 

echo "Creating MySQL database (if it doesn't exist)..."
mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"

echo "Setting file permissions..."
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl
chown -R www-data:www-data /var/www/pterodactyl/database
chmod -R 755 /var/www/pterodactyl/database

echo "Running database migrations..."
php artisan migrate --force

echo "Configuring Apache to serve Pterodactyl Panel on port $SERVER_PORT..."
sed -i "s/80/$SERVER_PORT/" /etc/apache2/ports.conf
echo "Setting ServerName in Apache configuration..."
echo "ServerName $SERVER_IP" >> /etc/apache2/apache2.conf

cat > /etc/apache2/sites-available/pterodactyl.conf << EOF
<VirtualHost *:$SERVER_PORT>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/pterodactyl/public

    <Directory /var/www/pterodactyl/public>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

echo "Enabling Apache site and mod_rewrite..."
a2ensite pterodactyl.conf
a2enmod rewrite

echo "Restarting Apache..."
service apache2 restart

echo "Creating user for Pterodactyl Panel..."
php artisan p:user:make

echo "Pterodactyl Panel installation is complete!"
echo "You can log in using the admin user created during the installation."

echo "Please complete the Pterodactyl setup through the web interface."
