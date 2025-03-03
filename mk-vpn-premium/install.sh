#!/bin/bash
#
# MK VPN Premium - Installation Script
# Version: 1.0.0
# Author: MK VPN Premium Team
# License: MIT
#

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display banner
echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}                   MK VPN PREMIUM                              ${NC}"
echo -e "${GREEN}                 INSTALLATION SCRIPT                           ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "${YELLOW}                    Version 1.0.0                             ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Check if system is Ubuntu 20.04 or higher
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        echo -e "${RED}This script requires Ubuntu operating system${NC}"
        exit 1
    fi
    
    # Extract version number
    version=$(echo "$VERSION_ID" | cut -d. -f1)
    if [[ "$version" -lt 20 ]]; then
        echo -e "${RED}This script requires Ubuntu 20.04 or higher${NC}"
        exit 1
    fi
else
    echo -e "${RED}Cannot determine operating system${NC}"
    exit 1
fi

# Ask for installation key
echo -e "${YELLOW}Please enter your installation key:${NC}"
read -s installation_key

if [[ "$installation_key" != "457251" ]]; then
    echo -e "${RED}Invalid installation key${NC}"
    exit 1
fi

echo -e "${GREEN}Installation key verified successfully${NC}"

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
apt-get update
apt-get install -y openssh-server openssh-client net-tools curl wget \
                   iptables ufw fail2ban python3 python3-pip jq \
                   openssl unzip zip git

# Create installation directory
install_dir="/opt/mk-vpn-premium"
echo -e "${YELLOW}Creating installation directory: $install_dir${NC}"
mkdir -p "$install_dir"

# Copy files to installation directory
echo -e "${YELLOW}Copying files to installation directory...${NC}"
cp -r ./* "$install_dir/"

# Make scripts executable
echo -e "${YELLOW}Making scripts executable...${NC}"
chmod +x "$install_dir/mk-vpn.sh"
chmod +x "$install_dir/scripts/"*.sh 2>/dev/null || true

# Create symbolic link
echo -e "${YELLOW}Creating symbolic link...${NC}"
ln -sf "$install_dir/mk-vpn.sh" /usr/local/bin/mk-vpn

# Create necessary directories
echo -e "${YELLOW}Creating necessary directories...${NC}"
mkdir -p "$install_dir/config" "$install_dir/scripts" "$install_dir/logs"

# Set permissions
echo -e "${YELLOW}Setting permissions...${NC}"
chown -R root:root "$install_dir"
chmod -R 750 "$install_dir"

# Run installation
echo -e "${YELLOW}Running installation...${NC}"
"$install_dir/mk-vpn.sh" install "$installation_key"

echo -e "${GREEN}MK VPN Premium has been installed successfully!${NC}"
echo -e "${YELLOW}You can now use the 'mk-vpn' command to manage your SSH connections.${NC}"
echo -e "${YELLOW}For help, run: mk-vpn help${NC}" 