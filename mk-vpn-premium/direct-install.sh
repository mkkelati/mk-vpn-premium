#!/bin/bash
#
# MK VPN Premium - Direct Installation Script
# Version: 1.0.0
# Author: MK VPN Premium Team
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

# Check system compatibility
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        echo -e "${RED}This script requires Ubuntu operating system${NC}"
        exit 1
    fi
    version=$(echo "$VERSION_ID" | cut -d. -f1)
    if [[ "$version" -lt 20 ]]; then
        echo -e "${RED}This script requires Ubuntu 20.04 or higher${NC}"
        exit 1
    fi
else
    echo -e "${RED}Cannot determine operating system${NC}"
    exit 1
fi

# Update system and install dependencies
echo -e "${YELLOW}Updating system and installing dependencies...${NC}"
apt-get update -y
apt-get upgrade -y
apt-get install -y git curl wget unzip zip

# Remove existing installation
echo -e "${YELLOW}Removing existing installation if any...${NC}"
rm -rf /root/mk-vpn-premium

# Clone repository
echo -e "${YELLOW}Downloading MK VPN Premium...${NC}"
git clone https://github.com/mkkelati/mk-vpn-premium.git /root/mk-vpn-premium

# Set up scripts
echo -e "${YELLOW}Setting up MK VPN Premium...${NC}"
cd /root/mk-vpn-premium/mk-vpn-premium
chmod +x mk-vpn.sh install.sh scripts/*.sh

# Create symbolic link
ln -sf /root/mk-vpn-premium/mk-vpn-premium/mk-vpn.sh /usr/local/bin/mk-vpn
chmod +x /usr/local/bin/mk-vpn

# Success message
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}       MK VPN Premium installed successfully!      ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${WHITE}              INSTALLATION DETAILS                 ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Command${NC}: mk-vpn"
echo -e "${CYAN}Version${NC}: 1.0.0"
echo -e "${CYAN}Author${NC}: MK VPN Premium Team"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}     Type 'mk-vpn' to start using the script     ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}" 