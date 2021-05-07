#!/bin/bash -e

# Enable StackScript trace log:
# exec > >(tee -i /var/log/stackscript.log)

# Use the following variables to control your install:
CICD_DEPLOYMENT_USER='devops'
CICD_DEPLOYMENT_PWD='<YOUR_PASSWORD>'
CICD_APPLICATION_FOLDER='netcoreapp'

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


