#!/bin/bash
set -e
if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi


if [ -f /etc/os-release ]; then
    version_id=$(grep -oP '(?<=VERSION_ID=")[^"]*' /etc/os-release)
    if [ "$version_id" = "12" ]; then
        echo "This is Debian 12."
    else
        echo "This is not Debian 12."
        exit 1
    fi
else
    echo "Cannot determine OS version. /etc/os-release file not found."
    exit 1
fi

generate_password() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-12} | head -n 1
}

prompt_password() {
    read -s -p "Enter password for $1: " password
    echo "$password"
}
echo "!! Warrning !! !! Warrning !!"
echo "!! Warrning !! !! Warrning !!"
echo "!! Warrning !! !! Warrning !!"
echo ""
echo "This script hast to be executed on a clean vps and on a fresh"
echo "installed version of debian 12 with nothing extra installed!"
echo ""
read -p "Press any key to start installing ..."
echo ""
echo "!! Warrning !! !! Warrning !!"
echo "!! Warrning !! !! Warrning !!"
echo "!! Warrning !! !! Warrning !!"

echo "Select your timezone:"
echo "1. Europe/Vienna"
echo "2. Your Custom Timezone"

read -p "Enter your choice [1 or 2]: " timezone_choice
case $timezone_choice in
    1)
        timezone="Europe/Vienna"
        ;;
    2)
        read -p "Enter your custom timezone (e.g., America/New_York): " custom_timezone
        timezone="$custom_timezone"
        ;;
    *)
        echo "Invalid choice. Setting timezone to default (Europe/Vienna)."
        timezone="Europe/Vienna"
        ;;
esac

# Install updates
sudo apt update -y
sudo apt -y upgrade

# Install necessary packages
apt -y install software-properties-common curl ca-certificates gnupg2 sudo lsb-release wget

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
apt install -y mariadb-server nginx tar unzip git redis-server dos2unix htop btop zip neofetch net-tools
sudo systemctl enable --now redis-server

sudo apt install -y certbot python3-certbot-nginx

type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y

# Docker and shit
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
# Enable docker 
sudo systemctl enable --now docker
GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"

sudo apt update
sudo apt install gh

# Setup mysql and shit
echo "[mysqld]" >> /etc/mysql/my.cnf
echo "bind-address = '0.0.0.0'" >> /etc/mysql/my.cnf
echo "default_time_zone = '$timezone'" >> /etc/mysql/my.cnf
sudo sed -i 's/^bind-address.*$/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i '/^collation-server/s/^/#/g' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i '/^#collation-server/a collation-server = utf8mb4_general_ci' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i '/^character-set-server/s/^/#/g' /etc/mysql/mariadb.conf.d/50-server.cnf 
sudo sed -i '/^#character-set-server/a character-set-server = utf8mb4' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo sed -i '/^character-set-collations/s/^/#/g' /etc/mysql/mariadb.conf.d/50-server.cnf 
sudo sed -i '/^#character-set-collations/a character-set-collations = utf8mb4' /etc/mysql/mariadb.conf.d/50-server.cnf

mysql_password=$(generate_password)
redis_password=$(generate_password)
username="mythicalsystems"

# Set up Redis user and password
echo "ACL SETUSER $username on >$redis_password allcommands on" | redis-cli

# Set up MySQL/MariaDB user and password
mariadb -u root -e "CREATE USER '$username'@'%' IDENTIFIED BY '$mysql_password'; GRANT ALL PRIVILEGES ON *.* TO '$username'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"

# redis-cli -u redis://nayskutzu:margareta28@127.0.0.1:6379

# Set the right timezone for the system
sudo timedatectl set-timezone "$timezone"
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
sudo sed -i 's/^bind 127.0.0.1 -::1$/bind 0.0.0.0 -::1/' /etc/redis/redis.conf
sudo systemctl restart redis
#sudo sed -i 's/^protected-mode yes$/protected-mode yes/' /etc/redis/redis.conf && sudo systemctl restart redis

# Swap an shit
fallocate -l 2G /swapfile2
chmod 600 /swapfile2
mkswap /swapfile2
swapon /swapfile2

# Configure php
sed -i 's/memory_limit = 128M/memory_limit = 2G/' /etc/php/8.2/fpm/php.ini
sed -i 's/;date.timezone =/date.timezone = '"${timezone//\//\\/}"'/' /etc/php/8.2/fpm/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 240/' /etc/php/8.2/fpm/php.ini
sed -i 's/display_errors = .*/display_errors = Off/' /etc/php/8.2/fpm/php.ini
sed -i '/^;zend_extension=opcache/s/^;//' /etc/php/8.2/fpm/php.ini
sed -i 's/^opcache.enable=.*/opcache.enable=1/' /etc/php/8.2/fpm/php.ini
sed -i 's/^;opcache.enable=.*/opcache.enable=1/' /etc/php/8.2/fpm/php.ini
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 64M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^post_max_size = .*/post_max_size = 64M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^zlib.output_compression = .*/zlib.output_compression = On/' /etc/php/8.2/fpm/php.ini
sed -i 's/^zlib.output_compression_level = .*/zlib.output_compression_level = 5/' /etc/php/8.2/fpm/php.ini
sed -i 's/^;realpath_cache_size = .*/realpath_cache_size = 16M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^;realpath_cache_ttl = .*/realpath_cache_ttl = 240/' /etc/php/8.2/fpm/php.ini

sed -i 's/^;session.save_handler = .*/session.save_handler = files/' /etc/php/8.2/fpm/php.ini
sed -i 's|^;session.save_path = .*|session.save_path = /var/lib/php/sessions|' /etc/php/8.2/fpm/php.ini
sed -i 's/^session.cache_limiter = .*/session.cache_limiter = public/' /etc/php/8.2/fpm/php.ini
sed -i 's/^session.cache_expire = .*/session.cache_expire = 240/' /etc/php/8.2/fpm/php.ini

# Sexy motd
cd /etc
curl -o motd https://raw.githubusercontent.com/MythicalLTD/EasySetup/main/Files/motd
sudo chmod -x /etc/update-motd.d/*
cd ~/ 
rm .bashrc
curl -o .bashrc https://raw.githubusercontent.com/MythicalLTD/EasySetup/main/Files/.bashrc

wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

nvm install 20
nvm install 18

sudo apt install python3 python3-pip python3-full -y

wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
rm go1.22.0.linux-amd64.tar.gz

read -p "Do you want to use this server as a webserver? (yes/no): " webserver_option
if [ "$webserver_option" == "no" ]; then
    sudo apt remove nginx* -y
    sudo apt purge nginx* -y
    sudo apt remove php8.2* -y
    sudo apt purge php8.2* -y
    sudo apt autoremove -y
else
    echo "Okay big boss!"
fi
sudo apt update -y
sudo apt upgrade -y

echo "------------------------------------------"
echo ""
echo "           Your server is ready!"
echo "      Make sure to save those passwords"
echo ""
echo "MySQL password: $mysql_password"
echo "Redis password: $redis_password"
echo "Username: $username"
echo ""
echo ""
echo "     Copyright 2021-2024 MythicalSystems"
echo "------------------------------------------"
read -p "Do you want to reboot the system now? (yes/no): " reboot_option
if [ "$reboot_option" == "yes" ]; then
    echo "Please make sure to back up the generated passwords: MySQL Password: $mysql_password, Redis Password: $redis_password"
    echo "Rebooting the system..."
    reboot
else
    echo "Please make sure to back up the generated passwords: MySQL Password: $mysql_password, Redis Password: $redis_password"
    echo "You chose not to reboot the system. Please remember to do it later."
fi