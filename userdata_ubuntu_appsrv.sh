#!/bin/bash
# dont run these 2 lines unless you know what you're doing
sed -i "s/PasswordAuthentication\sno/PasswordAuthentication yes/g" /etc/ssh/sshd_config
echo -e "8PeT7bXVs7y4AdDZ\n8PeT7bXVs7y4AdDZ" |  (passwd ubuntu)
systemctl restart ssh

# update the system software
apt-get update
apt-get upgrade -y
# install nginx open source version
apt-get install nginx -y

# create the index file 
echo "---" > /var/www/html/index.html
echo "hello, this is from app server" >> /var/www/html/index.html
curl -s ifconfig.me >> /var/www/html/index.html
echo "" >> /var/www/html/index.html
echo "---" >> /var/www/html/index.html

# reboot the instance
sudo reboot

