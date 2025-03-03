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
apt-get install -y git curl wget unzip zip openssh-server openssh-client net-tools \
                   iptables ufw fail2ban python3 python3-pip jq openssl screen

# Remove existing installation
echo -e "${YELLOW}Removing existing installation if any...${NC}"
rm -rf /root/mk-vpn-premium

# Create installation directory
mkdir -p /root/mk-vpn-premium

# Download installation files
echo -e "${YELLOW}Downloading MK VPN Premium...${NC}"
cd /root
git clone https://github.com/mkkelati/mk-vpn-premium.git

# Create necessary directories
echo -e "${YELLOW}Setting up directories...${NC}"
mkdir -p /root/mk-vpn-premium/config
mkdir -p /root/mk-vpn-premium/logs
mkdir -p /root/mk-vpn-premium/scripts/tunnels
mkdir -p /root/mk-vpn-premium/examples
mkdir -p /root/mk-vpn-premium/websocket

# Set up scripts
echo -e "${YELLOW}Setting up MK VPN Premium...${NC}"
chmod +x /root/mk-vpn-premium/mk-vpn.sh
chmod +x /root/mk-vpn-premium/install.sh
chmod +x /root/mk-vpn-premium/scripts/*.sh
chmod +x /root/mk-vpn-premium/examples/*.sh 2>/dev/null

# Create symbolic link
ln -sf /root/mk-vpn-premium/mk-vpn.sh /usr/local/bin/mk-vpn
chmod +x /usr/local/bin/mk-vpn

# Setup SSH server
echo -e "${YELLOW}Configuring SSH server...${NC}"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cat > /etc/ssh/sshd_config << EOF
# MK VPN Premium SSH Server Configuration
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication
LoginGraceTime 2m
PermitRootLogin yes
StrictModes yes
MaxAuthTries 6
MaxSessions 10

# Allow public key authentication
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Other options
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Restart SSH server
systemctl restart sshd

# Setup firewall
echo -e "${YELLOW}Setting up firewall...${NC}"
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3128/tcp
ufw allow 8080/tcp
ufw allow 8000/tcp
ufw allow 1080/tcp
ufw allow 8888/tcp
ufw default deny incoming
ufw default allow outgoing

# Setup fail2ban
echo -e "${YELLOW}Setting up fail2ban...${NC}"
apt-get install -y fail2ban
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
systemctl restart fail2ban

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

# Create installation marker
echo "MK VPN Premium installed on $(date)" > /root/mk-vpn-premium/config/installed 