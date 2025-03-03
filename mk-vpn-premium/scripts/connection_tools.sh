#!/bin/bash
#
# MK VPN Premium - Connection Tools Installer
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

# Function to log messages
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] [$level] $message"
}

# Function to update and upgrade the system
update_system() {
    echo -e "${YELLOW}Updating and upgrading the system...${NC}"
    log "Updating and upgrading the system"
    apt-get update -y && apt-get upgrade -y
}

# Function to install SSH tools
install_ssh_tools() {
    echo -e "${YELLOW}Installing SSH tools...${NC}"
    log "Installing SSH tools"
    apt-get install -y openssh-server openssh-client
}

# Function to install proxy tools
install_proxy_tools() {
    echo -e "${YELLOW}Installing proxy tools...${NC}"
    log "Installing proxy tools"
    apt-get install -y squid
}

# Function to install VPN tools
install_vpn_tools() {
    echo -e "${YELLOW}Installing VPN tools...${NC}"
    log "Installing VPN tools"
    apt-get install -y openvpn wireguard-tools strongswan
}

# Function to install extra tools
install_extra_tools() {
    echo -e "${YELLOW}Installing extra tools...${NC}"
    log "Installing extra tools"
    apt-get install -y stunnel badvpn
}

# Main function
main() {
    update_system
    install_ssh_tools
    install_proxy_tools
    install_vpn_tools
    install_extra_tools
    echo -e "${GREEN}All tools installed successfully!${NC}"
    log "All tools installed successfully"
}

# Run main function
main 