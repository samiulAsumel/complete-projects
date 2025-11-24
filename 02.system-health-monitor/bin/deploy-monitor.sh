#!/bin/bash

########################################################
# Monitor Deployment Script
# Purpose: Deploy monitoring to all servers
# Author: samiulAsumel
########################################################

# Server list
SERVERS={
	"dev-web:192.168.56.10"
	"stage-db:192.168.56.11"
	"prod-app:192.168.56.12"
	"cicd-jenkis:192.168.56.13"
}

SSH_USER="devops"
SSH_KEY="~/.ssh/id-rsa"
SECURE_DIR="/opt/system-health-monitor"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "$GREEN Starting deployment of system health monitor... $NC"
echo -e "$GREEN   TechCorp Monitor Deployment  $NC"
echo -e "$GREEN -------------------------------- $NC"

# Create deployment package
echo "Creating deployment package..."
cd $SOURCE_DIR
sudo tar -czf /tmp/monitor-package.tar.gz bin/ config/ > /dev/null 2>&1

if [ $? -eq 0 ]; then
	echo -e "${GREEN} Package created successfully. ${NC}"
else
	echo -e "${RED} Failed to create package. Exiting. ${NC}"
	exit 1
fi

# Deploy to each server
for server_info in "${SERVER[@]}"; do
	SERVER_NAME=$(echo $server_info | cut -d: -f1)
	SERVER_IP=$(echo $server_info | cut -d: -f2)

	echo -e "${YELLOW} Deploying to $SERVER_NAME ($SERVER_IP)... ${NC}"

	# Copy package
	scp -i $SSH_KEY /tmp/monitor-package.tar.gz $SSH_USER@$SERVER_IP:/tmp/ >/dev/null 2>&1

	if [ $? -ne 0 ]; then
		echo -e "${RED} Failed to copy package to $SERVER_NAME ($SERVER_IP). ${NC}"
		continue
	fi

	# Extract and set permissions
	ssh -i $SSH_KEY $SSH_USER@$SERVER_IP << EOF
		sudo mkdir -p /opt/system-health-monitor/{bin,config,logs,reports}
        sudo tar -xzf /tmp/monitor-package.tar.gz -C /opt/system-health-monitor/
        sudo chmod +x /opt/system-health-monitor/bin/*.sh
        sudo chown -R root:root /opt/system-health-monitor
        sudo rm /tmp/monitor-package.tar.gz
        
        # Set up cron job
        (sudo crontab -l 2>/dev/null | grep -v health_check.sh; \
         echo "*/15 * * * * /opt/system-health-monitor/bin/health_check.sh >> /opt/system-health-monitor/logs/cron.log 2>&1") | sudo crontab -
        
        # Test script
        sudo /opt/system-health-monitor/bin/health_check.sh >/dev/null 2>&1
EOF

	if [ $? -eq 0 ]; then
		echo -e "${GREEN} Successfully deployed to $SERVER_NAME ($SERVER_IP). ${NC}"
	else
		echo -e "${RED} Failed to deploy to $SERVER_NAME ($SERVER_IP). ${NC}"
	fi
done

# Cleanup
rm /tmp/monitor-package.tar.gz

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"