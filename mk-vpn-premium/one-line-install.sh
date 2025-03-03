#!/bin/bash
#
# MK VPN Premium - One-Line Installation Script
# Version: 1.0.0
# Author: MK VPN Premium Team
#

# This script is designed to be run with:
# curl -s https://raw.githubusercontent.com/mkkelati/mk-vpn-premium/main/one-line-install.sh | bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Clear screen and show banner
clear
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${WHITE}           MK VPN PREMIUM INSTALLER               ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}              PREPARING INSTALLATION              ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"

# Check root access
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Download the direct installation script
echo -e "${YELLOW}Downloading installation script...${NC}"
cd /root
wget -O direct-install.sh https://raw.githubusercontent.com/mkkelati/mk-vpn-premium/main/direct-install.sh

# Make it executable
chmod +x direct-install.sh

# Run the installation script
echo -e "${YELLOW}Running installation script...${NC}"
./direct-install.sh

# Clean up
rm -f direct-install.sh

echo -e "${GREEN}Installation process completed!${NC}" 