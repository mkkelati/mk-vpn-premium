#!/bin/bash
#
# MK VPN Premium - SSH Tunnel Manager
# Version: 1.0.0
# Author: MK VPN Premium Team
# License: MIT
#

# Set script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PARENT_DIR/config"
LOGS_DIR="$PARENT_DIR/logs"
TUNNELS_DIR="$PARENT_DIR/scripts/tunnels"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="$LOGS_DIR/tunnel_manager-$(date +%Y-%m-%d).log"

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
    echo -e "${GREEN}                 SSH TUNNEL MANAGER                            ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${YELLOW}                    Version 1.0.0                             ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

# Function to create SSH tunnel
create_tunnel() {
    local type="$1"
    local name="$2"
    local local_port="$3"
    local remote_host="$4"
    local remote_port="$5"
    local ssh_host="$6"
    local ssh_user="${7:-root}"
    local ssh_port="${8:-22}"
    local ssh_key="${9}"
    
    # Validate parameters
    if [[ -z "$type" || -z "$name" || -z "$local_port" || -z "$ssh_host" ]]; then
        echo -e "${RED}Missing required parameters${NC}"
        echo -e "${YELLOW}Usage: create_tunnel <type> <name> <local_port> <remote_host> <remote_port> <ssh_host> [ssh_user] [ssh_port] [ssh_key]${NC}"
        log "Tunnel creation failed: Missing required parameters" "ERROR"
        return 1
    fi
    
    # Validate tunnel type
    if [[ "$type" != "local" && "$type" != "remote" && "$type" != "dynamic" ]]; then
        echo -e "${RED}Invalid tunnel type: $type${NC}"
        echo -e "${YELLOW}Available types: local, remote, dynamic${NC}"
        log "Tunnel creation failed: Invalid tunnel type: $type" "ERROR"
        return 1
    fi
    
    # For local and remote tunnels, remote_host and remote_port are required
    if [[ "$type" != "dynamic" && ( -z "$remote_host" || -z "$remote_port" ) ]]; then
        echo -e "${RED}Remote host and remote port are required for $type tunnels${NC}"
        log "Tunnel creation failed: Remote host and remote port are required for $type tunnels" "ERROR"
        return 1
    fi
    
    # Create tunnels directory if it doesn't exist
    mkdir -p "$TUNNELS_DIR"
    
    # Create tunnel script
    echo -e "${YELLOW}Creating $type SSH tunnel: $name${NC}"
    log "Creating $type SSH tunnel: $name"
    
    # Create tunnel script file
    cat > "$TUNNELS_DIR/tunnel_$name.sh" << EOF
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
pkill -f "ssh.*tunnel_$name"

# Start tunnel
EOF
    
    # Add tunnel command based on type
    if [[ "$type" == "local" ]]; then
        echo "ssh -N -L $local_port:$remote_host:$remote_port -p $ssh_port" >> "$TUNNELS_DIR/tunnel_$name.sh"
    elif [[ "$type" == "remote" ]]; then
        echo "ssh -N -R $remote_port:localhost:$local_port -p $ssh_port" >> "$TUNNELS_DIR/tunnel_$name.sh"
    elif [[ "$type" == "dynamic" ]]; then
        echo "ssh -N -D $local_port -p $ssh_port" >> "$TUNNELS_DIR/tunnel_$name.sh"
    fi
    
    # Add SSH key if provided
    if [[ -n "$ssh_key" && -f "$CONFIG_DIR/$ssh_key" ]]; then
        sed -i "s|ssh -N|ssh -N -i \"$CONFIG_DIR/$ssh_key\"|" "$TUNNELS_DIR/tunnel_$name.sh"
    fi
    
    # Add SSH user and host
    sed -i "s|$ssh_port\"*$|$ssh_port $ssh_user@$ssh_host\"|" "$TUNNELS_DIR/tunnel_$name.sh"
    
    # Make script executable
    chmod +x "$TUNNELS_DIR/tunnel_$name.sh"
    
    echo -e "${GREEN}SSH tunnel created successfully: $name${NC}"
    log "SSH tunnel created successfully: $name"
    
    # Create tunnel configuration file
    cat > "$CONFIG_DIR/tunnel_$name.conf" << EOF
TYPE=$type
LOCAL_PORT=$local_port
REMOTE_HOST=$remote_host
REMOTE_PORT=$remote_port
SSH_HOST=$ssh_host
SSH_USER=$ssh_user
SSH_PORT=$ssh_port
SSH_KEY=$ssh_key
EOF
    
    return 0
}

# Function to list SSH tunnels
list_tunnels() {
    echo -e "${YELLOW}Available SSH tunnels:${NC}"
    log "Listing SSH tunnels"
    
    # Check if there are any tunnels
    if [[ ! -f "$CONFIG_DIR/tunnel_"*.conf ]]; then
        echo -e "${CYAN}No SSH tunnels found${NC}"
        return 0
    fi
    
    # List tunnels
    find "$CONFIG_DIR" -name "tunnel_*.conf" | while read -r tunnel_conf; do
        name=$(basename "$tunnel_conf" .conf | sed 's/tunnel_//')
        
        # Load tunnel configuration
        source "$tunnel_conf"
        
        # Check if tunnel is running
        if pgrep -f "ssh.*tunnel_$name" > /dev/null; then
            status="${GREEN}Running${NC}"
        else
            status="${RED}Stopped${NC}"
        fi
        
        # Display tunnel information
        echo -e "${GREEN}- $name${NC} ($TYPE tunnel, status: $status)"
        echo -e "  Local Port: $LOCAL_PORT"
        
        if [[ "$TYPE" != "dynamic" ]]; then
            echo -e "  Remote: $REMOTE_HOST:$REMOTE_PORT"
        fi
        
        echo -e "  SSH: $SSH_USER@$SSH_HOST:$SSH_PORT"
        
        if [[ -n "$SSH_KEY" ]]; then
            echo -e "  SSH Key: $SSH_KEY"
        fi
        
        echo ""
    done
    
    return 0
}

# Function to start SSH tunnel
start_tunnel() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Tunnel name is required${NC}"
        log "Tunnel start failed: Tunnel name is required" "ERROR"
        return 1
    fi
    
    # Check if tunnel exists
    if [[ ! -f "$CONFIG_DIR/tunnel_$name.conf" ]]; then
        echo -e "${RED}Tunnel not found: $name${NC}"
        log "Tunnel not found: $name" "ERROR"
        return 1
    fi
    
    # Check if tunnel script exists
    if [[ ! -f "$TUNNELS_DIR/tunnel_$name.sh" ]]; then
        echo -e "${RED}Tunnel script not found: $name${NC}"
        log "Tunnel script not found: $name" "ERROR"
        return 1
    fi
    
    # Check if tunnel is already running
    if pgrep -f "ssh.*tunnel_$name" > /dev/null; then
        echo -e "${YELLOW}Tunnel is already running: $name${NC}"
        log "Tunnel is already running: $name"
        return 0
    fi
    
    # Start tunnel
    echo -e "${YELLOW}Starting SSH tunnel: $name${NC}"
    log "Starting SSH tunnel: $name"
    
    # Run tunnel script in background
    "$TUNNELS_DIR/tunnel_$name.sh" > /dev/null 2>&1 &
    
    # Wait a moment to check if tunnel started successfully
    sleep 2
    
    # Check if tunnel is running
    if pgrep -f "ssh.*tunnel_$name" > /dev/null; then
        echo -e "${GREEN}SSH tunnel started successfully: $name${NC}"
        log "SSH tunnel started successfully: $name"
        return 0
    else
        echo -e "${RED}Failed to start SSH tunnel: $name${NC}"
        log "Failed to start SSH tunnel: $name" "ERROR"
        return 1
    fi
}

# Function to stop SSH tunnel
stop_tunnel() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Tunnel name is required${NC}"
        log "Tunnel stop failed: Tunnel name is required" "ERROR"
        return 1
    fi
    
    # Check if tunnel exists
    if [[ ! -f "$CONFIG_DIR/tunnel_$name.conf" ]]; then
        echo -e "${RED}Tunnel not found: $name${NC}"
        log "Tunnel not found: $name" "ERROR"
        return 1
    fi
    
    # Check if tunnel is running
    if ! pgrep -f "ssh.*tunnel_$name" > /dev/null; then
        echo -e "${YELLOW}Tunnel is not running: $name${NC}"
        log "Tunnel is not running: $name"
        return 0
    fi
    
    # Stop tunnel
    echo -e "${YELLOW}Stopping SSH tunnel: $name${NC}"
    log "Stopping SSH tunnel: $name"
    
    # Kill tunnel process
    pkill -f "ssh.*tunnel_$name"
    
    # Wait a moment to check if tunnel stopped successfully
    sleep 2
    
    # Check if tunnel is still running
    if pgrep -f "ssh.*tunnel_$name" > /dev/null; then
        echo -e "${RED}Failed to stop SSH tunnel: $name${NC}"
        log "Failed to stop SSH tunnel: $name" "ERROR"
        return 1
    else
        echo -e "${GREEN}SSH tunnel stopped successfully: $name${NC}"
        log "SSH tunnel stopped successfully: $name"
        return 0
    fi
}

# Function to delete SSH tunnel
delete_tunnel() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Tunnel name is required${NC}"
        log "Tunnel deletion failed: Tunnel name is required" "ERROR"
        return 1
    fi
    
    # Check if tunnel exists
    if [[ ! -f "$CONFIG_DIR/tunnel_$name.conf" ]]; then
        echo -e "${RED}Tunnel not found: $name${NC}"
        log "Tunnel not found: $name" "ERROR"
        return 1
    fi
    
    # Stop tunnel if running
    if pgrep -f "ssh.*tunnel_$name" > /dev/null; then
        stop_tunnel "$name"
    fi
    
    # Delete tunnel files
    echo -e "${YELLOW}Deleting SSH tunnel: $name${NC}"
    log "Deleting SSH tunnel: $name"
    
    rm -f "$CONFIG_DIR/tunnel_$name.conf" "$TUNNELS_DIR/tunnel_$name.sh"
    
    echo -e "${GREEN}SSH tunnel deleted successfully: $name${NC}"
    log "SSH tunnel deleted successfully: $name"
    
    return 0
}

# Function to display tunnel status
status_tunnel() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        # List all tunnels with status
        list_tunnels
        return 0
    fi
    
    # Check if tunnel exists
    if [[ ! -f "$CONFIG_DIR/tunnel_$name.conf" ]]; then
        echo -e "${RED}Tunnel not found: $name${NC}"
        log "Tunnel not found: $name" "ERROR"
        return 1
    fi
    
    # Load tunnel configuration
    source "$CONFIG_DIR/tunnel_$name.conf"
    
    # Check if tunnel is running
    if pgrep -f "ssh.*tunnel_$name" > /dev/null; then
        status="${GREEN}Running${NC}"
        pid=$(pgrep -f "ssh.*tunnel_$name")
    else
        status="${RED}Stopped${NC}"
        pid="N/A"
    fi
    
    # Display tunnel information
    echo -e "${YELLOW}SSH Tunnel: $name${NC}"
    echo -e "Status: $status"
    echo -e "PID: $pid"
    echo -e "Type: $TYPE"
    echo -e "Local Port: $LOCAL_PORT"
    
    if [[ "$TYPE" != "dynamic" ]]; then
        echo -e "Remote: $REMOTE_HOST:$REMOTE_PORT"
    fi
    
    echo -e "SSH: $SSH_USER@$SSH_HOST:$SSH_PORT"
    
    if [[ -n "$SSH_KEY" ]]; then
        echo -e "SSH Key: $SSH_KEY"
    fi
    
    # If tunnel is running, check if port is actually listening
    if [[ "$status" == "${GREEN}Running${NC}" ]]; then
        if netstat -tuln | grep -q ":$LOCAL_PORT "; then
            echo -e "Port Status: ${GREEN}Listening${NC}"
        else
            echo -e "Port Status: ${RED}Not Listening${NC}"
        fi
    fi
    
    return 0
}

# Function to display help
display_help() {
    echo -e "${CYAN}Usage: $0 [command] [options]${NC}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}create <type> <name> <local_port> <remote_host> <remote_port> <ssh_host> [ssh_user] [ssh_port] [ssh_key]${NC}"
    echo -e "                                      Create SSH tunnel"
    echo -e "  ${GREEN}list${NC}                           List SSH tunnels"
    echo -e "  ${GREEN}start <name>${NC}                   Start SSH tunnel"
    echo -e "  ${GREEN}stop <name>${NC}                    Stop SSH tunnel"
    echo -e "  ${GREEN}status [name]${NC}                  Display SSH tunnel status"
    echo -e "  ${GREEN}delete <name>${NC}                  Delete SSH tunnel"
    echo -e "  ${GREEN}help${NC}                           Display this help message"
    echo ""
    echo -e "${YELLOW}Tunnel Types:${NC}"
    echo -e "  ${GREEN}local${NC}                          Local port forwarding (local:remote)"
    echo -e "  ${GREEN}remote${NC}                         Remote port forwarding (remote:local)"
    echo -e "  ${GREEN}dynamic${NC}                        Dynamic port forwarding (SOCKS proxy)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$0 create local web 8080 example.com 80 server1 root 22 my_key${NC}"
    echo -e "                                      Create local tunnel to example.com:80"
    echo -e "  ${GREEN}$0 create remote ssh 2222 localhost 22 server1${NC}"
    echo -e "                                      Create remote tunnel to local SSH"
    echo -e "  ${GREEN}$0 create dynamic proxy 1080 - - server1${NC}"
    echo -e "                                      Create SOCKS proxy"
    echo -e "  ${GREEN}$0 start web${NC}                   Start web tunnel"
    echo -e "  ${GREEN}$0 status web${NC}                  Display web tunnel status"
    echo -e "  ${GREEN}$0 stop web${NC}                    Stop web tunnel"
    echo -e "  ${GREEN}$0 delete web${NC}                  Delete web tunnel"
    echo ""
}

# Main function
main() {
    # Create directories if they don't exist
    mkdir -p "$CONFIG_DIR" "$LOGS_DIR" "$TUNNELS_DIR"
    
    # Parse command line arguments
    local command="$1"
    shift
    
    case "$command" in
        "create")
            create_tunnel "$@"
            ;;
        "list")
            list_tunnels
            ;;
        "start")
            start_tunnel "$@"
            ;;
        "stop")
            stop_tunnel "$@"
            ;;
        "status")
            status_tunnel "$@"
            ;;
        "delete")
            delete_tunnel "$@"
            ;;
        "help"|"")
            display_banner
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