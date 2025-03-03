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
NC='\033[0m'

# Function to display banner
display_banner() {
    clear
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${GREEN}                   MK VPN PREMIUM                              ${NC}"
    echo -e "${GREEN}                 SSH SCRIPT MANAGER                            ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${YELLOW}                    Version 1.0.0                             ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

# Function to check root access
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}

# Function to check system compatibility
check_system() {
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
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y git curl wget unzip zip
}

# Function to clone and install MK VPN Premium
install_mk_vpn() {
    echo -e "${YELLOW}Installing MK VPN Premium...${NC}"
    
    # Remove existing installation if any
    rm -rf /root/mk-vpn-premium
    
    # Clone the repository
    git clone https://github.com/mkkelati/mk-vpn-premium.git /root/mk-vpn-premium
    
    # Navigate to the correct directory
    cd /root/mk-vpn-premium/mk-vpn-premium
    
    # Make scripts executable
    chmod +x install.sh mk-vpn.sh scripts/*.sh
    
    # Run the installation script
    ./install.sh
    
    echo -e "${GREEN}MK VPN Premium has been installed successfully!${NC}"
    echo -e "${YELLOW}You can now use the 'mk-vpn' command to manage your SSH connections.${NC}"
}

# Main installation process
main() {
    display_banner
    check_root
    check_system
    install_dependencies
    install_mk_vpn
}

# Start installation
main 