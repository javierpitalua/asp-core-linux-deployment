#!/bin/bash -e

# Enable StackScript trace log:
# exec > >(tee -i /var/log/stackscript.log)

# Use the following variables to control your install:
CICD_DEPLOYMENT_USER='devops'
CICD_DEPLOYMENT_PWD='<YOUR_PASSWORD>'
CICD_APPLICATION_NAME='netcoreapp'
CICD_APPLICATION_DOMAIN='<YOUR_DOMAIN_OR_IP>'
SOURCE_REPO=''

echo Creating a CICD user...
sudo adduser --disabled-password --gecos "" "$CICD_DEPLOYMENT_USER"

echo Set CICD user pwd...
echo "$CICD_DEPLOYMENT_USER":"$CICD_DEPLOYMENT_PWD" | sudo chpasswd

echo Adding privileges to CICD...
sudo usermod -aG sudo "$CICD_DEPLOYMENT_USER"
echo CICD user succesfully created.                                                     

echo Updating system...
sudo apt-get update

echo Installing unzip command...
sudo apt-get install unzip

echo Installing transport https...
sudo apt-get install -y apt-transport-https

echo Adding microsoft packages...
wget https://packages.microsoft.com/config/ubuntu/20.10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update

echo Adding .Net Core 3.1 Runtime...
sudo apt-get install -y aspnetcore-runtime-3.1

echo Downloading default .net core application...
sudo wget -O deployment-package.zip https://github.com/javierpitalua/asp-core-linux-deployment/raw/main/dist/deployment-package.zip
echo Download complete.

echo Unzipping application file...
sudo mkdir -p "/var/www/$CICD_APPLICATION_NAME"
sudo unzip deployment-package.zip -d "/var/www/$CICD_APPLICATION_NAME"

echo Running app as a service...

sudo wget https://raw.githubusercontent.com/javierpitalua/asp-core-linux-deployment/main/service-template.txt
sudo sed -i "s/application-name/$CICD_APPLICATION_NAME/g" "service-template.txt"
sudo cp "service-template.txt" "/etc/systemd/system/$CICD_APPLICATION_NAME.service"
sudo cat "/etc/systemd/system/$CICD_APPLICATION_NAME.service"

echo Installing nginx...
sudo apt-get install nginx

echo Updating domain name on Nginx...
sudo wget https://raw.githubusercontent.com/javierpitalua/asp-core-linux-deployment/main/nginx-config.txt
sudo sed -i "s/domain-name/$CICD_APPLICATION_DOMAIN/g" "nginx-config.txt"
sudo cp "nginx-config.txt" /etc/nginx/sites-available/default
echo Nginx configuration file:
sudo cat /etc/nginx/sites-available/default

echo Enabling application service...
sudo systemctl enable "$CICD_APPLICATION_NAME.service"
sudo systemctl start "$CICD_APPLICATION_NAME.service"
sudo systemctl status "$CICD_APPLICATION_NAME.service"

echo Starting nginx...
sudo service nginx start

echo Script completed.
