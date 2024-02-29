#!/bin/bash
set -e
if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi
# Install updates
sudo apt update -y
sudo apt -y upgrade

# Install necessary packages
apt -y install software-properties-common curl ca-certificates gnupg2 sudo lsb-release

# Add repository for PHP
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list

curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg

# Add repository for Redis
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

# Update  package lists
apt update -y

# Install PHP and required extensions
apt install -y php8.2 php8.2-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,ssh2}

# MariaDB repo setup script
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Install the rest of dependencies
apt install -y mariadb-server nginx tar unzip git redis-server dos2unix htop btop zip
sudo systemctl enable --now redis-server

sudo apt install -y certbot python3-certbot-nginx

# Docker and shit
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
# Enable docker 
sudo systemctl enable --now docker
GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"

# Setup mysql and shit
echo "[mysqld]" >> /etc/mysql/my.cnf
echo "bind-address = '0.0.0.0'" >> /etc/mysql/my.cnf
echo "default_time_zone = '+01:00'" >> /etc/mysql/my.cnf
sudo sed -i 's/^bind-address.*$/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i '/^collation-server/s/^/#/g' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i '/^#collation-server/a collation-server = utf8mb4_general_ci' /etc/mysql/mariadb.conf.d/50-server.cnf

# Set the right timezone for the system
sudo timedatectl set-timezone Europe/Vienna
timedatectl

wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0
sudo apt-get install -y dotnet-runtime-8.0

# Composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
echo '0 23 * * * certbot renew --quiet --deploy-hook "systemctl restart nginx"' | crontab -

# Setup redis 
sudo sed -i 's/^bind 127.0.0.1 -::1$/bind 0.0.0.0 -::1/' /etc/redis/redis.conf && sudo systemctl restart redis
sudo sed -i 's/^protected-mode yes$/protected-mode no/' /etc/redis/redis.conf && sudo systemctl restart redis

# Swap an shit
fallocate -l 2G /swapfile2
chmod 600 /swapfile2
mkswap /swapfile2
swapon /swapfile2
# Sexy motd
cd /etc
curl -o motd https://raw.githubusercontent.com/MythicalLTD/EasySetup/main/Files/motd
sudo chmod -x /etc/update-motd.d/*
cd ~/ 
rm .bashrc
curl -o .bashrc https://raw.githubusercontent.com/MythicalLTD/EasySetup/main/Files/.bashrc
