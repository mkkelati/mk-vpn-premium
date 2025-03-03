#!/bin/bash
#
# MK VPN Premium - Example: Setup Server
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
echo -e "${GREEN}                 EXAMPLE: SETUP SERVER                         ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "${YELLOW}                    Version 1.0.0                             ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Check if MK VPN Premium is installed
if ! command -v mk-vpn &> /dev/null; then
    echo -e "${RED}MK VPN Premium is not installed${NC}"
    echo -e "${YELLOW}Please install MK VPN Premium first${NC}"
    exit 1
fi

# Ask for server details
echo -e "${YELLOW}Please enter server details:${NC}"
echo -e "${YELLOW}----------------------------${NC}"
echo -n "Server name: "
read server_name
echo -n "Server IP: "
read server_ip
echo -n "SSH user (default: root): "
read server_user
server_user=${server_user:-root}
echo -n "SSH port (default: 22): "
read server_port
server_port=${server_port:-22}

# Generate SSH key
echo -e "${YELLOW}Generating SSH key...${NC}"
mk-vpn key generate "${server_name}_key"

# Add SSH connection
echo -e "${YELLOW}Adding SSH connection...${NC}"
mk-vpn conn add "$server_name" "$server_ip" "$server_user" "$server_port" "${server_name}_key"

# Test SSH connection
echo -e "${YELLOW}Testing SSH connection...${NC}"
mk-vpn conn test "$server_name"

# If connection test failed, exit
if [[ $? -ne 0 ]]; then
    echo -e "${RED}SSH connection test failed${NC}"
    echo -e "${YELLOW}Please check your server details and try again${NC}"
    exit 1
fi

# Ask if user wants to setup SSH server
echo -e "${YELLOW}Do you want to setup SSH server? (y/n)${NC}"
read setup_server

if [[ "$setup_server" == "y" || "$setup_server" == "Y" ]]; then
    # Setup SSH server
    echo -e "${YELLOW}Setting up SSH server...${NC}"
    mk-vpn server config
fi

# Ask if user wants to setup firewall
echo -e "${YELLOW}Do you want to setup firewall? (y/n)${NC}"
read setup_firewall

if [[ "$setup_firewall" == "y" || "$setup_firewall" == "Y" ]]; then
    # Setup firewall
    echo -e "${YELLOW}Setting up firewall...${NC}"
    mk-vpn exec "$server_name" "ufw --force enable && ufw allow 22/tcp && ufw default deny incoming && ufw default allow outgoing"
fi

# Ask if user wants to setup fail2ban
echo -e "${YELLOW}Do you want to setup fail2ban? (y/n)${NC}"
read setup_fail2ban

if [[ "$setup_fail2ban" == "y" || "$setup_fail2ban" == "Y" ]]; then
    # Setup fail2ban
    echo -e "${YELLOW}Setting up fail2ban...${NC}"
    mk-vpn exec "$server_name" "apt-get update && apt-get install -y fail2ban && systemctl enable fail2ban && systemctl start fail2ban"
fi

# Ask if user wants to create SSH tunnel
echo -e "${YELLOW}Do you want to create SSH tunnel? (y/n)${NC}"
read create_tunnel

if [[ "$create_tunnel" == "y" || "$create_tunnel" == "Y" ]]; then
    # Ask for tunnel details
    echo -e "${YELLOW}Please enter tunnel details:${NC}"
    echo -e "${YELLOW}----------------------------${NC}"
    echo -n "Tunnel name: "
    read tunnel_name
    echo -n "Tunnel type (local/remote/dynamic): "
    read tunnel_type
    echo -n "Local port: "
    read local_port
    
    if [[ "$tunnel_type" != "dynamic" ]]; then
        echo -n "Remote host: "
        read remote_host
        echo -n "Remote port: "
        read remote_port
    else
        remote_host="-"
        remote_port="-"
    fi
    
    # Create SSH tunnel
    echo -e "${YELLOW}Creating SSH tunnel...${NC}"
    mk-vpn tunnel create "$tunnel_type" "$tunnel_name" "$local_port" "$remote_host" "$remote_port" "$server_name"
    
    # Start SSH tunnel
    echo -e "${YELLOW}Starting SSH tunnel...${NC}"
    mk-vpn tunnel start "$tunnel_name"
fi

echo -e "${GREEN}Server setup completed successfully${NC}"
echo -e "${YELLOW}You can now connect to your server using:${NC}"
echo -e "${GREEN}mk-vpn conn connect $server_name${NC}"

if [[ "$create_tunnel" == "y" || "$create_tunnel" == "Y" ]]; then
    echo -e "${YELLOW}Your SSH tunnel is running:${NC}"
    echo -e "${GREEN}mk-vpn tunnel status $tunnel_name${NC}"
fi

echo -e "${YELLOW}Thank you for using MK VPN Premium!${NC}" 