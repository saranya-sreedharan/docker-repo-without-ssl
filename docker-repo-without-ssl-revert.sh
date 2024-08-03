#!/bin/bash

# Script to revert Docker private registry setup and configuration changes
# Run this script with sudo permissions.

RED='\033[0;31m'
NC='\033[0m'
YELLOW='\033[33m'
GREEN='\033[32m'

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}" >&2
    exit 1
fi

echo -e "${YELLOW}Step 1: Stopping Docker registry...${NC}"
cd /registry
docker-compose down

echo -e "${YELLOW}Step 2: Removing Docker registry files...${NC}"
rm -rf /registry

echo -e "${GREEN}Docker private registry setup reverted successfully.${NC}"

# Additional Steps for Docker Configuration Removal
echo -e "${YELLOW}Step 3: Removing Docker insecure registry configuration...${NC}"
rm -f /etc/docker/daemon.json

echo -e "${YELLOW}Step 4: Restarting Docker service...${NC}"
systemctl restart docker

echo -e "${GREEN}Docker configuration changes reverted successfully.${NC}"
