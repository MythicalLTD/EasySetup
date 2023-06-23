#!/bin/bash
set -e
if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi
echo "    Welcome to MythicalSystems Script"
echo "With this script you can setup your vps"
read -p "Press any key to start installing ..."
cd /etc/ssh
rm sshd_config
curl -o sshd_config https://raw.githubusercontent.com/MythicalLTD/EasySetup/main/Files/sshd_config
systemctl restart ssh
systemctl restart sshd
echo "We enabled root login and password auth"
echo "Let's set up a password for the root user!"
sudo passwd
echo "Done, keep in mind that now you will have to ssh to your server using your serverip@root and not serverip@ubuntu"
echo "And use the password you typed in early"
read -p "Press any key to continue with installing updates"
sudo apt install neofetch -y
sudo apt update
sudo apt -y upgrade
echo "We are done with installing updates, press any key, so we can set up your firewall!"
read -p "Press any key to continue with setting up the firewall"
iptables -I FORWARD 1 -p tcp -m tcp --dport 465 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 25 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 26 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 995 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 143 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 22 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 110 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 993 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 587 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 5222 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 5269 -j DROP
iptables -I FORWARD 1 -p tcp -m tcp --dport 5443 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 465 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 25 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 26 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 995 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 143 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 22 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 110 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 993 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 587 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 5222 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 5269 -j DROP
iptables -I FORWARD 1 -p udp -m udp --dport 5443 -j DROP
ufw disable
iptables-save > /etc/iptables/rules.v4
echo "We are done with setting up the firewall, press any key, so we can set up your swap!"
read -p "Press any key to continue with setting up the swap"
fallocate -l 12G /swapfile2
chmod 600 /swapfile2
mkswap /swapfile2
swapon /swapfile2
echo "We are done with setting up the swap, press any key, so we can set up your motd and terminal color!"
read -p "Press any key to continue with setting up the motd and terminal color"
cd /etc
curl -o motd https://raw.githubusercontent.com/MythicalLTD/EasySetup/main/Files/motd
sudo chmod -x /etc/update-motd.d/*
cd ~/ 
rm .bashrc
curl -o .bashrc https://raw.githubusercontent.com/MythicalLTD/EasySetup/main/Files/.bashrc
echo "We are done with setting up your vps"
read -p "Press any key to reboot your server! (THIS IS REQUIRED SO UPDATES WILL BE INSTALLED)"
sudo reboot
