#!/bin/bash

# install nginx
sudo amazon-linux-extras enable nginx1
sudo yum clean metadata
sudo yum -y install nginx

# additional nginx configuration
cd /etc/nginx/conf.d
sudo touch proxy_pass.conf
echo 'server{location / {proxy_pass http://10.0.1.4/;}}' | sudo tee proxy_pass.conf


#sudo systemctl start nginx
sudo systemctl start nginx