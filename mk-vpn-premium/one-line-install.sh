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

# Install git if not installed
echo -e "${YELLOW}Checking and installing git...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y git > /dev/null 2>&1

# Clone the repository directly
echo -e "${YELLOW}Downloading MK VPN Premium...${NC}"
cd /root
rm -rf mk-vpn-premium
git clone https://github.com/mkkelati/mk-vpn-premium.git

# Check if clone was successful
if [ ! -d "/root/mk-vpn-premium" ]; then
    echo -e "${RED}Failed to download MK VPN Premium. Please check your internet connection and try again.${NC}"
    exit 1
fi

# Make scripts executable
echo -e "${YELLOW}Setting up MK VPN Premium...${NC}"
chmod +x /root/mk-vpn-premium/direct-install.sh
chmod +x /root/mk-vpn-premium/mk-vpn.sh
chmod +x /root/mk-vpn-premium/install.sh
chmod +x /root/mk-vpn-premium/scripts/*.sh 2>/dev/null
chmod +x /root/mk-vpn-premium/examples/*.sh 2>/dev/null

# Run the installation script
echo -e "${YELLOW}Running installation script...${NC}"
cd /root/mk-vpn-premium
./direct-install.sh

echo -e "${GREEN}Installation process completed!${NC}" 