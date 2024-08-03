
#!/bin/bash

# Script to setup Docker private registry without SSL on Ubuntu 20.04
# Run this script with sudo permissions.

RED='\033[0;31m'
NC='\033[0m'
YELLOW='\033[33m'
GREEN='\033[32m'

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}" >&2
    exit 1
fi

echo -e "${YELLOW}Step 1: Updating packages...${NC}"
apt-get update && apt-get upgrade -y

echo -e "${YELLOW}Step 2: Installing Docker...${NC}"
if ! [ -x "$(command -v docker)" ]; then
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
fi

echo -e "${YELLOW}Step 3: Installing Docker Compose...${NC}"
if ! [ -x "$(command -v docker-compose)" ]; then
    apt-get install -y docker-compose
fi

echo -e "${YELLOW}Step 4: Installing apache2-utils for htpasswd...${NC}"
apt-get install -y apache2-utils

echo -e "${YELLOW}Step 5: Creating directories for Docker registry...${NC}"
mkdir -p /registry/data /registry/auth

echo -e "${YELLOW}Step 6: Creating authentication file...${NC}"
htpasswd -Bbc /registry/auth/htpasswd admin adminpassword

echo -e "${YELLOW}Step 7: Creating Docker Compose file...${NC}"
cat <<EOF > /registry/docker-compose.yml
version: '3'

services:
  registry:
    image: registry:2
    ports:
      - "5000:5000"
    restart: always
    environment:
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
    volumes:
      - /registry/data:/var/lib/registry
      - /registry/auth:/auth
EOF

echo -e "${YELLOW}Step 8: Starting Docker registry...${NC}"
cd /registry
docker-compose up -d

echo -e "${GREEN}Docker private registry setup completed successfully.${NC}"

# Additional Steps for Docker Configuration
echo -e "${YELLOW}Step 9: Configuring Docker for insecure registry...${NC}"
echo '{"insecure-registries": ["10.18.22.172:5000"]}' > /etc/docker/daemon.json

echo -e "${YELLOW}Step 10: Restarting Docker service...${NC}"
systemctl restart docker

# Docker Login to Private Registry
echo -e "${YELLOW}Step 11: Logging into the private registry...${NC}"
sudo docker login 10.18.22.172:5000

# Instructions for client machines
echo -e "${YELLOW}To login to the private registry from any machine, use the following command:${NC}"
echo -e "${YELLOW} sudo docker login <your-server-ip>:5000${NC}"

# Push and Pull Test Instructions
echo -e "${YELLOW}To test the registry, follow these steps:${NC}"
echo -e "1. Pull a small image: sudo docker pull busybox"
echo -e "2. Tag the image: sudo docker tag busybox <your-server-ip>:5000/busybox:test"
echo -e "3. Push the image: sudo docker push <your-server-ip>:5000/busybox:test"
echo -e "4. On another machine, pull the image: sudo docker pull <your-server-ip>:5000/busybox:test"
