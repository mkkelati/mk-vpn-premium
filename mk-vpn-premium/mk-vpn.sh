#!/bin/bash
#
# MK VPN Premium - SSH Script Manager
# Version: 1.0.0
# Author: MK VPN Premium Team
# License: MIT
# Installation Key: 457251
#

# Set script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_DIR="$SCRIPT_DIR/config"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
LOGS_DIR="$SCRIPT_DIR/logs"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="$LOGS_DIR/mk-vpn-$(date +%Y-%m-%d).log"

# Function to log messages
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Function to display banner
display_banner() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}               MK VPN PREMIUM MANAGER              ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    MAIN MENU                      ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
}

# Function to display menu
display_menu() {
    echo -e "\n${WHITE}SSH MANAGEMENT${NC}"
    echo -e "${CYAN}[01]${NC} • ${WHITE}Create SSH User${NC}"
    echo -e "${CYAN}[02]${NC} • ${WHITE}Delete SSH User${NC}"
    echo -e "${CYAN}[03]${NC} • ${WHITE}Renew SSH User${NC}"
    echo -e "${CYAN}[04]${NC} • ${WHITE}Check SSH Users${NC}"
    
    echo -e "\n${WHITE}TUNNEL MANAGEMENT${NC}"
    echo -e "${CYAN}[05]${NC} • ${WHITE}Create SSH Tunnel${NC}"
    echo -e "${CYAN}[06]${NC} • ${WHITE}Delete SSH Tunnel${NC}"
    echo -e "${CYAN}[07]${NC} • ${WHITE}Check SSH Tunnels${NC}"
    
    echo -e "\n${WHITE}PROXY MANAGEMENT${NC}"
    echo -e "${CYAN}[08]${NC} • ${WHITE}Setup Squid Proxy${NC}"
    echo -e "${CYAN}[09]${NC} • ${WHITE}Setup SOCKS5 Proxy${NC}"
    echo -e "${CYAN}[10]${NC} • ${WHITE}Setup HTTP Proxy${NC}"
    
    echo -e "\n${WHITE}VPN MANAGEMENT${NC}"
    echo -e "${CYAN}[11]${NC} • ${WHITE}Setup OpenVPN${NC}"
    echo -e "${CYAN}[12]${NC} • ${WHITE}Setup WireGuard${NC}"
    echo -e "${CYAN}[13]${NC} • ${WHITE}Setup IKEv2${NC}"
    
    echo -e "\n${WHITE}EXTRA TOOLS${NC}"
    echo -e "${CYAN}[14]${NC} • ${WHITE}Setup STunnel${NC}"
    echo -e "${CYAN}[15]${NC} • ${WHITE}Setup BadVPN${NC}"
    echo -e "${CYAN}[16]${NC} • ${WHITE}Setup Cloudflare WS${NC}"
    echo -e "${CYAN}[17]${NC} • ${WHITE}Setup UDPGW${NC}"
    
    echo -e "\n${WHITE}SYSTEM TOOLS${NC}"
    echo -e "${CYAN}[18]${NC} • ${WHITE}Check System Status${NC}"
    echo -e "${CYAN}[19]${NC} • ${WHITE}Check Port Status${NC}"
    echo -e "${CYAN}[20]${NC} • ${WHITE}Backup Users${NC}"
    echo -e "${CYAN}[21]${NC} • ${WHITE}Restore Users${NC}"
    
    echo -e "\n${CYAN}[00]${NC} • ${RED}Exit Script${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
}

# Load menu functions
source "$SCRIPTS_DIR/menu.sh"

# Function to handle menu selection
handle_menu() {
    read -p "Select Menu : " choice
    case $choice in
        01|1) create_ssh_user ;;
        02|2) delete_ssh_user ;;
        03|3) renew_ssh_user ;;
        04|4) check_ssh_users ;;
        05|5) create_ssh_tunnel ;;
        06|6) delete_ssh_tunnel ;;
        07|7) check_ssh_tunnels ;;
        08|8) setup_squid_proxy ;;
        09|9) setup_socks5_proxy ;;
        10) setup_http_proxy ;;
        11) setup_openvpn ;;
        12) setup_wireguard ;;
        13) setup_ikev2 ;;
        14) setup_stunnel ;;
        15) setup_badvpn ;;
        16) setup_cloudflare_ws ;;
        17) setup_udpgw ;;
        18) check_system_status ;;
        19) check_port_status ;;
        20) backup_users ;;
        21) restore_users ;;
        00|0) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
    esac
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}

# Function to check system compatibility
check_system() {
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
    
    echo -e "${GREEN}System compatibility check passed${NC}"
    log "System compatibility check passed"
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    log "Installing dependencies"
    
    apt-get update
    apt-get install -y openssh-server openssh-client net-tools curl wget \
                       iptables ufw fail2ban python3 python3-pip jq \
                       openssl unzip zip git
    
    # Check if installation was successful
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Dependencies installed successfully${NC}"
        log "Dependencies installed successfully"
    else
        echo -e "${RED}Failed to install dependencies${NC}"
        log "Failed to install dependencies" "ERROR"
        exit 1
    fi
}

# Function to verify installation key
verify_key() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        echo -e "${RED}Installation key is required${NC}"
        return 1
    fi
    
    if [[ "$key" != "457251" ]]; then
        echo -e "${RED}Invalid installation key${NC}"
        log "Invalid installation key attempt: $key" "ERROR"
        return 1
    fi
    
    echo -e "${GREEN}Installation key verified successfully${NC}"
    log "Installation key verified successfully"
    return 0
}

# Function to install MK VPN Premium
install_mk_vpn() {
    local key="$1"
    
    # Verify installation key
    verify_key "$key" || return 1
    
    display_banner
    
    echo -e "${YELLOW}Installing MK VPN Premium...${NC}"
    log "Installing MK VPN Premium"
    
    # Check if running as root
    check_root
    
    # Check system compatibility
    check_system
    
    # Install dependencies
    install_dependencies
    
    # Create necessary directories
    mkdir -p "$CONFIG_DIR" "$SCRIPTS_DIR" "$LOGS_DIR"
    
    # Setup SSH server
    manage_ssh_server config
    
    # Setup firewall
    setup_firewall
    
    # Setup fail2ban
    setup_fail2ban
    
    # Create installation marker
    echo "MK VPN Premium installed on $(date)" > "$CONFIG_DIR/installed"
    
    echo -e "${GREEN}MK VPN Premium installed successfully${NC}"
    log "MK VPN Premium installed successfully"
}

# Function to uninstall MK VPN Premium
uninstall_mk_vpn() {
    display_banner
    
    echo -e "${YELLOW}Uninstalling MK VPN Premium...${NC}"
    log "Uninstalling MK VPN Premium"
    
    # Backup configuration
    backup_ssh_config
    
    # Remove directories
    rm -rf "$CONFIG_DIR" "$SCRIPTS_DIR" "$LOGS_DIR"
    
    echo -e "${GREEN}MK VPN Premium uninstalled successfully${NC}"
    log "MK VPN Premium uninstalled successfully"
}

# Function to display help
display_help() {
    display_banner
    
    echo -e "${CYAN}Usage: $0 [command] [options]${NC}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}install <key>${NC}                  Install MK VPN Premium"
    echo -e "  ${GREEN}uninstall${NC}                      Uninstall MK VPN Premium"
    echo -e "  ${GREEN}help${NC}                           Display this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$0 install 457251${NC}              Install MK VPN Premium"
    echo -e "  ${GREEN}$0 uninstall${NC}                   Uninstall MK VPN Premium"
    echo ""
}

# Function to setup firewall
setup_firewall() {
    echo -e "${YELLOW}Setting up firewall...${NC}"
    log "Setting up firewall"
    
    # Enable UFW
    ufw --force enable
    
    # Allow SSH
    ufw allow 22/tcp
    
    # Allow common ports
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 3128/tcp
    ufw allow 8080/tcp
    ufw allow 8000/tcp
    ufw allow 1080/tcp
    ufw allow 8888/tcp
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    echo -e "${GREEN}Firewall setup completed${NC}"
    log "Firewall setup completed"
}

# Function to setup fail2ban
setup_fail2ban() {
    echo -e "${YELLOW}Setting up fail2ban...${NC}"
    log "Setting up fail2ban"
    
    # Install fail2ban if not installed
    apt-get install -y fail2ban
    
    # Create fail2ban configuration
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
    
    # Restart fail2ban
    systemctl restart fail2ban
    
    echo -e "${GREEN}Fail2ban setup completed${NC}"
    log "Fail2ban setup completed"
}

# Function to manage SSH server
manage_ssh_server() {
    local action="$1"
    
    case "$action" in
        "status")
            systemctl status sshd
            ;;
        "start")
            systemctl start sshd
            echo -e "${GREEN}SSH server started${NC}"
            log "SSH server started"
            ;;
        "stop")
            systemctl stop sshd
            echo -e "${GREEN}SSH server stopped${NC}"
            log "SSH server stopped"
            ;;
        "restart")
            systemctl restart sshd
            echo -e "${GREEN}SSH server restarted${NC}"
            log "SSH server restarted"
            ;;
        "config")
            # Backup original config
            cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
            
            # Configure SSH server
            echo -e "${YELLOW}Configuring SSH server...${NC}"
            log "Configuring SSH server"
            
            # Set secure SSH configuration
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

# Disable password authentication (optional, uncomment to enable)
#PasswordAuthentication no
#PermitEmptyPasswords no

# Other options
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
            
            # Restart SSH server
            systemctl restart sshd
            
            echo -e "${GREEN}SSH server configured successfully${NC}"
            log "SSH server configured successfully"
            ;;
        *)
            echo -e "${RED}Invalid action: $action${NC}"
            echo -e "${YELLOW}Available actions: status, start, stop, restart, config${NC}"
            return 1
            ;;
    esac
}

# Function to backup SSH configuration
backup_ssh_config() {
    local backup_file="$LOGS_DIR/ssh_backup_$(date +%Y%m%d%H%M%S).tar.gz"
    
    echo -e "${YELLOW}Backing up SSH configuration...${NC}"
    log "Backing up SSH configuration"
    
    # Create backup
    tar -czf "$backup_file" -C / etc/ssh /etc/fail2ban "$CONFIG_DIR" "$SCRIPTS_DIR"
    
    echo -e "${GREEN}SSH configuration backed up to: $backup_file${NC}"
    log "SSH configuration backed up to: $backup_file"
}

# Function to restore SSH configuration
restore_ssh_config() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        echo -e "${RED}Backup file is required${NC}"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}Backup file not found: $backup_file${NC}"
        log "Backup file not found: $backup_file" "ERROR"
        return 1
    fi
    
    echo -e "${YELLOW}Restoring SSH configuration from: $backup_file${NC}"
    log "Restoring SSH configuration from: $backup_file"
    
    # Extract backup
    tar -xzf "$backup_file" -C /
    
    # Restart services
    systemctl restart sshd
    systemctl restart fail2ban
    
    echo -e "${GREEN}SSH configuration restored successfully${NC}"
    log "SSH configuration restored successfully"
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if running as root
    check_root
    
    # Create necessary directories if they don't exist
    mkdir -p "$CONFIG_DIR" "$SCRIPTS_DIR" "$LOGS_DIR"
    
    # Process command line arguments
    if [[ $# -gt 0 ]]; then
        case "$1" in
            "install")
                install_mk_vpn "$2"
                ;;
            "uninstall")
                uninstall_mk_vpn
                ;;
            "help")
                display_help
                ;;
            *)
                echo -e "${RED}Invalid command: $1${NC}"
                display_help
                exit 1
                ;;
        esac
    else
        # Run main menu
        main
    fi
fi

# Main function
main() {
    while true; do
        display_banner
        display_menu
        handle_menu
    done
}

# Start script if no arguments provided
if [[ $# -eq 0 ]]; then
    main
fi 