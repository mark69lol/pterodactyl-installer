#!/bin/bash

echo "### Pterodactyl Installer By: mark69lol ###"
echo "Pterodactyl Panel Installation Script"
echo "Please provide the following information:"
read -p "Enter the server IP (e.g., 127.0.0.1): " SERVER_IP
read -p "Enter the server port (default 8080): " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-8080}

echo "Updating system..."
apt update -y && apt upgrade -y

echo "Installing dependencies..."
apt install -y apache2 sqlite3 php php-cli php-sqlite3 php-gd php-xml php-mbstring php-curl git curl unzip sudo python3 python3-pip

echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo "Downloading Pterodactyl Panel..."
cd /var/www
git clone https://github.com/pterodactyl/panel.git pterodactyl
cd pterodactyl

echo "Installing Pterodactyl dependencies..."
composer install --no-dev --optimize-autoloader

echo "Configuring SQLite Database..."
cp .env.example .env
sed -i "s/DB_CONNECTION=mysql/DB_CONNECTION=sqlite/" .env
sed -i "s|DB_DATABASE=|DB_DATABASE=/var/www/pterodactyl/database/panel.sqlite|" .env

echo "Creating SQLite database file..."
touch /var/www/pterodactyl/database/panel.sqlite

echo "Setting file permissions..."
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl
chown -R www-data:www-data /var/www/pterodactyl/database
chmod -R 755 /var/www/pterodactyl/database

echo "Clearing the database (if it exists)..."
rm -f /var/www/pterodactyl/database/panel.sqlite
touch /var/www/pterodactyl/database/panel.sqlite

echo "Fixing database column issue for 'last_run' column..."
sqlite3 /var/www/pterodactyl/database/panel.sqlite <<EOF
  PRAGMA foreign_keys=off;
  CREATE TABLE tasks_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    last_run TIMESTAMP NULL,
    -- other columns that the table might have, replicate them from the old table
    -- For example, add all columns from the old tasks table here
  );
  INSERT INTO tasks_new (id, last_run)
    SELECT id, last_run FROM tasks;
  DROP TABLE tasks;
  ALTER TABLE tasks_new RENAME TO tasks;
  PRAGMA foreign_keys=on;
EOF

echo "Running database migrations..."
php artisan migrate --force

echo "Configuring Apache to serve Pterodactyl Panel on port $SERVER_PORT..."
sed -i "s/80/$SERVER_PORT/" /etc/apache2/ports.conf

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

echo "Creating admin user for Pterodactyl Panel..."
php artisan p:user:make

echo "Pterodactyl Panel installation is complete!"
echo "You can log in using the admin user created during the installation."

echo "Please complete the Pterodactyl setup through the web interface."
