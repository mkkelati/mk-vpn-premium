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
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${GREEN}                   MK VPN PREMIUM                              ${NC}"
    echo -e "${GREEN}                 SSH SCRIPT MANAGER                            ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${YELLOW}                    Version 1.0.0                             ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
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

# Function to manage SSH keys
manage_ssh_keys() {
    local action="$1"
    
    case "$action" in
        "generate")
            local key_name="$2"
            local key_type="${3:-rsa}"
            local key_bits="${4:-4096}"
            
            if [[ -z "$key_name" ]]; then
                echo -e "${RED}Key name is required${NC}"
                return 1
            fi
            
            ssh-keygen -t "$key_type" -b "$key_bits" -f "$CONFIG_DIR/$key_name" -N ""
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}SSH key generated successfully: $CONFIG_DIR/$key_name${NC}"
                log "SSH key generated successfully: $CONFIG_DIR/$key_name"
            else
                echo -e "${RED}Failed to generate SSH key${NC}"
                log "Failed to generate SSH key" "ERROR"
                return 1
            fi
            ;;
        "list")
            echo -e "${CYAN}Available SSH keys:${NC}"
            find "$CONFIG_DIR" -name "*.pub" | while read -r key; do
                base_key=$(basename "$key" .pub)
                echo -e "${GREEN}- $base_key${NC}"
            done
            ;;
        "delete")
            local key_name="$2"
            
            if [[ -z "$key_name" ]]; then
                echo -e "${RED}Key name is required${NC}"
                return 1
            fi
            
            if [[ -f "$CONFIG_DIR/$key_name" ]]; then
                rm -f "$CONFIG_DIR/$key_name" "$CONFIG_DIR/$key_name.pub"
                echo -e "${GREEN}SSH key deleted successfully: $key_name${NC}"
                log "SSH key deleted successfully: $key_name"
            else
                echo -e "${RED}SSH key not found: $key_name${NC}"
                log "SSH key not found: $key_name" "ERROR"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Invalid action: $action${NC}"
            echo -e "${YELLOW}Available actions: generate, list, delete${NC}"
            return 1
            ;;
    esac
}

# Function to manage SSH connections
manage_ssh_connections() {
    local action="$1"
    
    case "$action" in
        "add")
            local name="$2"
            local host="$3"
            local user="${4:-root}"
            local port="${5:-22}"
            local key="${6}"
            
            if [[ -z "$name" || -z "$host" ]]; then
                echo -e "${RED}Name and host are required${NC}"
                return 1
            fi
            
            # Create connection config
            cat > "$CONFIG_DIR/conn_$name.conf" << EOF
HOST=$host
USER=$user
PORT=$port
KEY=$key
EOF
            echo -e "${GREEN}SSH connection added successfully: $name${NC}"
            log "SSH connection added successfully: $name"
            ;;
        "list")
            echo -e "${CYAN}Available SSH connections:${NC}"
            find "$CONFIG_DIR" -name "conn_*.conf" | while read -r conn; do
                name=$(basename "$conn" .conf | sed 's/conn_//')
                host=$(grep "HOST=" "$conn" | cut -d= -f2)
                user=$(grep "USER=" "$conn" | cut -d= -f2)
                port=$(grep "PORT=" "$conn" | cut -d= -f2)
                echo -e "${GREEN}- $name${NC} ($user@$host:$port)"
            done
            ;;
        "connect")
            local name="$2"
            
            if [[ -z "$name" ]]; then
                echo -e "${RED}Connection name is required${NC}"
                return 1
            fi
            
            if [[ ! -f "$CONFIG_DIR/conn_$name.conf" ]]; then
                echo -e "${RED}Connection not found: $name${NC}"
                log "Connection not found: $name" "ERROR"
                return 1
            fi
            
            # Load connection config
            source "$CONFIG_DIR/conn_$name.conf"
            
            # Connect to SSH server
            if [[ -n "$KEY" && -f "$CONFIG_DIR/$KEY" ]]; then
                echo -e "${YELLOW}Connecting to $USER@$HOST:$PORT using key $KEY...${NC}"
                log "Connecting to $USER@$HOST:$PORT using key $KEY"
                ssh -i "$CONFIG_DIR/$KEY" -p "$PORT" "$USER@$HOST"
            else
                echo -e "${YELLOW}Connecting to $USER@$HOST:$PORT...${NC}"
                log "Connecting to $USER@$HOST:$PORT"
                ssh -p "$PORT" "$USER@$HOST"
            fi
            ;;
        "delete")
            local name="$2"
            
            if [[ -z "$name" ]]; then
                echo -e "${RED}Connection name is required${NC}"
                return 1
            fi
            
            if [[ -f "$CONFIG_DIR/conn_$name.conf" ]]; then
                rm -f "$CONFIG_DIR/conn_$name.conf"
                echo -e "${GREEN}SSH connection deleted successfully: $name${NC}"
                log "SSH connection deleted successfully: $name"
            else
                echo -e "${RED}Connection not found: $name${NC}"
                log "Connection not found: $name" "ERROR"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Invalid action: $action${NC}"
            echo -e "${YELLOW}Available actions: add, list, connect, delete${NC}"
            return 1
            ;;
    esac
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

# Function to setup firewall
setup_firewall() {
    echo -e "${YELLOW}Setting up firewall...${NC}"
    log "Setting up firewall"
    
    # Enable UFW
    ufw --force enable
    
    # Allow SSH
    ufw allow 22/tcp
    
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

# Function to create SSH tunnels
create_ssh_tunnel() {
    local type="$1"
    local name="$2"
    local local_port="$3"
    local remote_host="$4"
    local remote_port="$5"
    local ssh_host="$6"
    local ssh_user="${7:-root}"
    local ssh_port="${8:-22}"
    local ssh_key="${9}"
    
    if [[ -z "$type" || -z "$name" || -z "$local_port" || -z "$remote_host" || -z "$remote_port" || -z "$ssh_host" ]]; then
        echo -e "${RED}Missing required parameters${NC}"
        echo -e "${YELLOW}Usage: create_ssh_tunnel <type> <name> <local_port> <remote_host> <remote_port> <ssh_host> [ssh_user] [ssh_port] [ssh_key]${NC}"
        return 1
    fi
    
    # Create tunnel script
    cat > "$SCRIPTS_DIR/tunnel_$name.sh" << EOF
#!/bin/bash

# SSH Tunnel: $name
# Type: $type
# Local Port: $local_port
# Remote Host: $remote_host
# Remote Port: $remote_port
# SSH Host: $ssh_host
# SSH User: $ssh_user
# SSH Port: $ssh_port
# SSH Key: $ssh_key

# Kill existing tunnel with the same name
pkill -f "ssh.*$name"

# Start tunnel
EOF
    
    if [[ "$type" == "local" ]]; then
        echo "ssh -N -L $local_port:$remote_host:$remote_port -p $ssh_port" >> "$SCRIPTS_DIR/tunnel_$name.sh"
    elif [[ "$type" == "remote" ]]; then
        echo "ssh -N -R $remote_port:localhost:$local_port -p $ssh_port" >> "$SCRIPTS_DIR/tunnel_$name.sh"
    elif [[ "$type" == "dynamic" ]]; then
        echo "ssh -N -D $local_port -p $ssh_port" >> "$SCRIPTS_DIR/tunnel_$name.sh"
    else
        echo -e "${RED}Invalid tunnel type: $type${NC}"
        echo -e "${YELLOW}Available types: local, remote, dynamic${NC}"
        rm -f "$SCRIPTS_DIR/tunnel_$name.sh"
        return 1
    fi
    
    if [[ -n "$ssh_key" && -f "$CONFIG_DIR/$ssh_key" ]]; then
        sed -i "s|ssh -N|ssh -N -i \"$CONFIG_DIR/$ssh_key\"|" "$SCRIPTS_DIR/tunnel_$name.sh"
    fi
    
    sed -i "s|$ssh_port\"$|$ssh_port $ssh_user@$ssh_host\"|" "$SCRIPTS_DIR/tunnel_$name.sh"
    
    # Make script executable
    chmod +x "$SCRIPTS_DIR/tunnel_$name.sh"
    
    echo -e "${GREEN}SSH tunnel created successfully: $name${NC}"
    log "SSH tunnel created successfully: $name"
}

# Function to manage SSH tunnels
manage_ssh_tunnels() {
    local action="$1"
    
    case "$action" in
        "create")
            shift
            create_ssh_tunnel "$@"
            ;;
        "list")
            echo -e "${CYAN}Available SSH tunnels:${NC}"
            find "$SCRIPTS_DIR" -name "tunnel_*.sh" | while read -r tunnel; do
                name=$(basename "$tunnel" .sh | sed 's/tunnel_//')
                type=$(grep "# Type:" "$tunnel" | cut -d: -f2 | tr -d ' ')
                local_port=$(grep "# Local Port:" "$tunnel" | cut -d: -f2 | tr -d ' ')
                remote_host=$(grep "# Remote Host:" "$tunnel" | cut -d: -f2 | tr -d ' ')
                remote_port=$(grep "# Remote Port:" "$tunnel" | cut -d: -f2 | tr -d ' ')
                ssh_host=$(grep "# SSH Host:" "$tunnel" | cut -d: -f2 | tr -d ' ')
                
                echo -e "${GREEN}- $name${NC} ($type tunnel, local port: $local_port, remote: $remote_host:$remote_port, via: $ssh_host)"
            done
            ;;
        "start")
            local name="$2"
            
            if [[ -z "$name" ]]; then
                echo -e "${RED}Tunnel name is required${NC}"
                return 1
            fi
            
            if [[ ! -f "$SCRIPTS_DIR/tunnel_$name.sh" ]]; then
                echo -e "${RED}Tunnel not found: $name${NC}"
                log "Tunnel not found: $name" "ERROR"
                return 1
            fi
            
            # Start tunnel in background
            "$SCRIPTS_DIR/tunnel_$name.sh" &
            
            echo -e "${GREEN}SSH tunnel started: $name${NC}"
            log "SSH tunnel started: $name"
            ;;
        "stop")
            local name="$2"
            
            if [[ -z "$name" ]]; then
                echo -e "${RED}Tunnel name is required${NC}"
                return 1
            fi
            
            # Kill tunnel process
            pkill -f "ssh.*$name"
            
            echo -e "${GREEN}SSH tunnel stopped: $name${NC}"
            log "SSH tunnel stopped: $name"
            ;;
        "delete")
            local name="$2"
            
            if [[ -z "$name" ]]; then
                echo -e "${RED}Tunnel name is required${NC}"
                return 1
            fi
            
            if [[ -f "$SCRIPTS_DIR/tunnel_$name.sh" ]]; then
                # Stop tunnel if running
                pkill -f "ssh.*$name"
                
                # Delete tunnel script
                rm -f "$SCRIPTS_DIR/tunnel_$name.sh"
                
                echo -e "${GREEN}SSH tunnel deleted: $name${NC}"
                log "SSH tunnel deleted: $name"
            else
                echo -e "${RED}Tunnel not found: $name${NC}"
                log "Tunnel not found: $name" "ERROR"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Invalid action: $action${NC}"
            echo -e "${YELLOW}Available actions: create, list, start, stop, delete${NC}"
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
    echo -e "  ${GREEN}key <action> [options]${NC}         Manage SSH keys"
    echo -e "  ${GREEN}conn <action> [options]${NC}        Manage SSH connections"
    echo -e "  ${GREEN}server <action>${NC}                Manage SSH server"
    echo -e "  ${GREEN}tunnel <action> [options]${NC}      Manage SSH tunnels"
    echo -e "  ${GREEN}backup${NC}                         Backup SSH configuration"
    echo -e "  ${GREEN}restore <file>${NC}                 Restore SSH configuration"
    echo -e "  ${GREEN}help${NC}                           Display this help message"
    echo ""
    echo -e "${YELLOW}Key Actions:${NC}"
    echo -e "  ${GREEN}generate <name> [type] [bits]${NC}  Generate SSH key"
    echo -e "  ${GREEN}list${NC}                           List SSH keys"
    echo -e "  ${GREEN}delete <name>${NC}                  Delete SSH key"
    echo ""
    echo -e "${YELLOW}Connection Actions:${NC}"
    echo -e "  ${GREEN}add <name> <host> [user] [port] [key]${NC}  Add SSH connection"
    echo -e "  ${GREEN}list${NC}                                   List SSH connections"
    echo -e "  ${GREEN}connect <name>${NC}                         Connect to SSH server"
    echo -e "  ${GREEN}delete <name>${NC}                          Delete SSH connection"
    echo ""
    echo -e "${YELLOW}Server Actions:${NC}"
    echo -e "  ${GREEN}status${NC}                         Display SSH server status"
    echo -e "  ${GREEN}start${NC}                          Start SSH server"
    echo -e "  ${GREEN}stop${NC}                           Stop SSH server"
    echo -e "  ${GREEN}restart${NC}                        Restart SSH server"
    echo -e "  ${GREEN}config${NC}                         Configure SSH server"
    echo ""
    echo -e "${YELLOW}Tunnel Actions:${NC}"
    echo -e "  ${GREEN}create <type> <name> <local_port> <remote_host> <remote_port> <ssh_host> [ssh_user] [ssh_port] [ssh_key]${NC}"
    echo -e "                                      Create SSH tunnel"
    echo -e "  ${GREEN}list${NC}                           List SSH tunnels"
    echo -e "  ${GREEN}start <name>${NC}                   Start SSH tunnel"
    echo -e "  ${GREEN}stop <name>${NC}                    Stop SSH tunnel"
    echo -e "  ${GREEN}delete <name>${NC}                  Delete SSH tunnel"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$0 install 457251${NC}              Install MK VPN Premium"
    echo -e "  ${GREEN}$0 key generate my_key${NC}         Generate SSH key"
    echo -e "  ${GREEN}$0 conn add server1 192.168.1.100 root 22 my_key${NC}"
    echo -e "                                      Add SSH connection"
    echo -e "  ${GREEN}$0 conn connect server1${NC}        Connect to SSH server"
    echo -e "  ${GREEN}$0 tunnel create local proxy 8080 example.com 80 server1${NC}"
    echo -e "                                      Create local SSH tunnel"
    echo ""
}

# Main function
main() {
    # Create directories if they don't exist
    mkdir -p "$CONFIG_DIR" "$SCRIPTS_DIR" "$LOGS_DIR"
    
    # Parse command line arguments
    local command="$1"
    shift
    
    case "$command" in
        "install")
            install_mk_vpn "$1"
            ;;
        "uninstall")
            uninstall_mk_vpn
            ;;
        "key")
            manage_ssh_keys "$@"
            ;;
        "conn")
            manage_ssh_connections "$@"
            ;;
        "server")
            manage_ssh_server "$@"
            ;;
        "tunnel")
            manage_ssh_tunnels "$@"
            ;;
        "backup")
            backup_ssh_config
            ;;
        "restore")
            restore_ssh_config "$1"
            ;;
        "help"|"")
            display_help
            ;;
        *)
            echo -e "${RED}Invalid command: $command${NC}"
            display_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 