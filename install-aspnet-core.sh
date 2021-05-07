#!/bin/bash -e

# Enable StackScript trace log:
# exec > >(tee -i /var/log/stackscript.log)

# Use the following variables to control your install:
CICD_DEPLOYMENT_USER='devops'
CICD_DEPLOYMENT_PWD='<YOUR_PASSWORD>'
CICD_APPLICATION_FOLDER='netcoreapp'
CICD_APPLICATION_DOMAIN='netcoreapp'

echo Creating a CICD user...
sudo adduser --disabled-password --gecos "" "$CICD_DEPLOYMENT_USER"

echo Set CICD user pwd...
echo "$CICD_DEPLOYMENT_USER":"$CICD_DEPLOYMENT_PWD" | sudo chpasswd

echo Adding privileges to CICD...
sudo usermod -aG sudo "$CICD_DEPLOYMENT_USER"
echo CICD user succesfully created.                                                     

echo Updating system...
sudo apt-get update

echo Installing transport https...
sudo apt-get install -y apt-transport-https

echo Adding microsoft packages...
wget https://packages.microsoft.com/config/ubuntu/20.10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update

echo Adding .Net Core 3.1 Runtime...
sudo apt-get install -y aspnetcore-runtime-3.1

echo Downloading default .net core application...
wget -O deployment-package.zip https://github.com/javierpitalua/asp-core-linux-deployment/raw/main/dist/deployment-package.zip
echo Download complete.

echo Unzipping application file...
mkdir -p "/home/$CICD_DEPLOYMENT_USER/$CICD_APPLICATION_FOLDER"
unzip deployment-package.zip -d "/home/$CICD_DEPLOYMENT_USER/$CICD_APPLICATION_FOLDER"

echo Installing nginx...
sudo apt-get install nginx

cat > /etc/nginx/sites-available/default << EOF
server {
    listen        80;
    server_name  [$domain-name];
    location / {
        proxy_pass         http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
EOF

echo Updating domain name on Nginx...
sed "s/[$domain-name]/$CICD_APPLICATION_DOMAIN/g" /etc/nginx/sites-available/default

echo Updating domain name on Nginx...
sudo service nginx start