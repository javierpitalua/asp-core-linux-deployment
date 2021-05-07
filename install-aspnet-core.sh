#!/bin/bash -e

# Enable StackScript trace log:
# exec > >(tee -i /var/log/stackscript.log)

# Use the following variables to control your install:
CICD_DEPLOYMENT_USER='devops'
CICD_DEPLOYMENT_PWD='<YOUR_PASSWORD>'
CICD_APPLICATION_NAME='netcoreapp'
CICD_APPLICATION_DLL='BasicWebApplication.dll'
CICD_APPLICATION_DOMAIN='<YOUR_DOMAIN_OR_IP>'

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
sudo mkdir -p "/var/www/$CICD_APPLICATION_NAME"
sudo unzip deployment-package.zip -d "/var/www/$CICD_APPLICATION_NAME"

echo Running app as a service...

sudo cat > "/etc/systemd/system/$CICD_APPLICATION_NAME.service" << EOF
[Unit]
Description=.net core web application

[Service]
WorkingDirectory=/var/www/[application-name]
ExecStart=/usr/bin/dotnet /var/www/[$application-name]/[application-dll]
Restart=always
# Restart service after 10 seconds if the dotnet service crashes:
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=[application-name]
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOF

echo Updating service file
sudo sed "s/[application-name]/$CICD_APPLICATION_NAME/g" "/etc/systemd/system/$CICD_APPLICATION_NAME.service"
sudo sed "s/[application-dll]/$CICD_APPLICATION_DLL/g" "/etc/systemd/system/$CICD_APPLICATION_NAME.service"

echo systemd configuration:
sudo cat "/etc/systemd/system/$CICD_APPLICATION_NAME.service"

echo Installing nginx...
sudo apt-get install nginx

sudo cat > /etc/nginx/sites-available/default << EOF
server {
    listen        80;
    server_name   [domain-name];
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
sed "s/[domain-name]/$CICD_APPLICATION_DOMAIN/g" /etc/nginx/sites-available/default

echo Nginx configuration file:
cat /etc/nginx/sites-available/default

echo Enabling application service...
sudo systemctl enable "$CICD_APPLICATION_NAME.service"
sudo systemctl start "$CICD_APPLICATION_NAME.service"
sudo systemctl status "$CICD_APPLICATION_NAME.service"

echo Starting nginx...
sudo service nginx start

echo Script completed.
