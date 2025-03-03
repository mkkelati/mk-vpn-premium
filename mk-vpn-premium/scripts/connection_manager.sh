#!/bin/bash
#
# MK VPN Premium - SSH Connection Manager
# Version: 1.0.0
# Author: MK VPN Premium Team
# License: MIT
#

# Set script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PARENT_DIR/config"
LOGS_DIR="$PARENT_DIR/logs"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="$LOGS_DIR/connection_manager-$(date +%Y-%m-%d).log"

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
    echo -e "${GREEN}               SSH CONNECTION MANAGER                          ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${YELLOW}                    Version 1.0.0                             ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

# Function to add SSH connection
add_connection() {
    local name="$1"
    local host="$2"
    local user="${3:-root}"
    local port="${4:-22}"
    local key="${5}"
    local password="${6}"
    
    if [[ -z "$name" || -z "$host" ]]; then
        echo -e "${RED}Connection name and host are required${NC}"
        log "Connection addition failed: Connection name and host are required" "ERROR"
        return 1
    fi
    
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    # Check if connection already exists
    if [[ -f "$CONFIG_DIR/conn_$name.conf" ]]; then
        echo -e "${RED}Connection already exists: $name${NC}"
        log "Connection already exists: $name" "ERROR"
        return 1
    fi
    
    # Create connection configuration
    echo -e "${YELLOW}Adding SSH connection: $name${NC}"
    log "Adding SSH connection: $name"
    
    cat > "$CONFIG_DIR/conn_$name.conf" << EOF
HOST=$host
USER=$user
PORT=$port
KEY=$key
PASSWORD=$password
EOF
    
    echo -e "${GREEN}SSH connection added successfully: $name${NC}"
    log "SSH connection added successfully: $name"
    
    return 0
}

# Function to list SSH connections
list_connections() {
    echo -e "${YELLOW}Available SSH connections:${NC}"
    log "Listing SSH connections"
    
    # Check if there are any connections
    if [[ ! -f "$CONFIG_DIR/conn_"*.conf ]]; then
        echo -e "${CYAN}No SSH connections found${NC}"
        return 0
    fi
    
    # List connections
    find "$CONFIG_DIR" -name "conn_*.conf" | while read -r conn_conf; do
        name=$(basename "$conn_conf" .conf | sed 's/conn_//')
        
        # Load connection configuration
        host=$(grep "HOST=" "$conn_conf" | cut -d= -f2)
        user=$(grep "USER=" "$conn_conf" | cut -d= -f2)
        port=$(grep "PORT=" "$conn_conf" | cut -d= -f2)
        key=$(grep "KEY=" "$conn_conf" | cut -d= -f2)
        
        # Display connection information
        echo -e "${GREEN}- $name${NC} ($user@$host:$port)"
        
        if [[ -n "$key" ]]; then
            echo -e "  SSH Key: $key"
        fi
    done
    
    return 0
}

# Function to connect to SSH server
connect_to_server() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Connection name is required${NC}"
        log "Connection failed: Connection name is required" "ERROR"
        return 1
    fi
    
    # Check if connection exists
    if [[ ! -f "$CONFIG_DIR/conn_$name.conf" ]]; then
        echo -e "${RED}Connection not found: $name${NC}"
        log "Connection not found: $name" "ERROR"
        return 1
    fi
    
    # Load connection configuration
    source "$CONFIG_DIR/conn_$name.conf"
    
    # Connect to SSH server
    echo -e "${YELLOW}Connecting to SSH server: $name ($USER@$HOST:$PORT)${NC}"
    log "Connecting to SSH server: $name ($USER@$HOST:$PORT)"
    
    if [[ -n "$KEY" && -f "$CONFIG_DIR/$KEY" ]]; then
        echo -e "${YELLOW}Using SSH key: $KEY${NC}"
        ssh -i "$CONFIG_DIR/$KEY" -p "$PORT" "$USER@$HOST"
    else
        ssh -p "$PORT" "$USER@$HOST"
    fi
    
    # Check connection status
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SSH connection successful: $name${NC}"
        log "SSH connection successful: $name"
        return 0
    else
        echo -e "${RED}SSH connection failed: $name${NC}"
        log "SSH connection failed: $name" "ERROR"
        return 1
    fi
}

# Function to delete SSH connection
delete_connection() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Connection name is required${NC}"
        log "Connection deletion failed: Connection name is required" "ERROR"
        return 1
    fi
    
    # Check if connection exists
    if [[ ! -f "$CONFIG_DIR/conn_$name.conf" ]]; then
        echo -e "${RED}Connection not found: $name${NC}"
        log "Connection not found: $name" "ERROR"
        return 1
    fi
    
    # Delete connection
    echo -e "${YELLOW}Deleting SSH connection: $name${NC}"
    log "Deleting SSH connection: $name"
    
    rm -f "$CONFIG_DIR/conn_$name.conf"
    
    echo -e "${GREEN}SSH connection deleted successfully: $name${NC}"
    log "SSH connection deleted successfully: $name"
    
    return 0
}

# Function to edit SSH connection
edit_connection() {
    local name="$1"
    local field="$2"
    local value="$3"
    
    if [[ -z "$name" || -z "$field" || -z "$value" ]]; then
        echo -e "${RED}Connection name, field, and value are required${NC}"
        log "Connection edit failed: Connection name, field, and value are required" "ERROR"
        return 1
    fi
    
    # Check if connection exists
    if [[ ! -f "$CONFIG_DIR/conn_$name.conf" ]]; then
        echo -e "${RED}Connection not found: $name${NC}"
        log "Connection not found: $name" "ERROR"
        return 1
    fi
    
    # Check if field is valid
    if [[ "$field" != "HOST" && "$field" != "USER" && "$field" != "PORT" && "$field" != "KEY" && "$field" != "PASSWORD" ]]; then
        echo -e "${RED}Invalid field: $field${NC}"
        echo -e "${YELLOW}Valid fields: HOST, USER, PORT, KEY, PASSWORD${NC}"
        log "Invalid field: $field" "ERROR"
        return 1
    fi
    
    # Edit connection
    echo -e "${YELLOW}Editing SSH connection: $name (setting $field to $value)${NC}"
    log "Editing SSH connection: $name (setting $field to $value)"
    
    # Update field in configuration file
    sed -i "s|$field=.*|$field=$value|" "$CONFIG_DIR/conn_$name.conf"
    
    echo -e "${GREEN}SSH connection edited successfully: $name${NC}"
    log "SSH connection edited successfully: $name"
    
    return 0
}

# Function to test SSH connection
test_connection() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Connection name is required${NC}"
        log "Connection test failed: Connection name is required" "ERROR"
        return 1
    fi
    
    # Check if connection exists
    if [[ ! -f "$CONFIG_DIR/conn_$name.conf" ]]; then
        echo -e "${RED}Connection not found: $name${NC}"
        log "Connection not found: $name" "ERROR"
        return 1
    fi
    
    # Load connection configuration
    source "$CONFIG_DIR/conn_$name.conf"
    
    # Test SSH connection
    echo -e "${YELLOW}Testing SSH connection: $name ($USER@$HOST:$PORT)${NC}"
    log "Testing SSH connection: $name ($USER@$HOST:$PORT)"
    
    if [[ -n "$KEY" && -f "$CONFIG_DIR/$KEY" ]]; then
        ssh -i "$CONFIG_DIR/$KEY" -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$USER@$HOST" exit
    else
        ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$USER@$HOST" exit
    fi
    
    # Check connection status
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SSH connection test successful: $name${NC}"
        log "SSH connection test successful: $name"
        return 0
    else
        echo -e "${RED}SSH connection test failed: $name${NC}"
        log "SSH connection test failed: $name" "ERROR"
        return 1
    fi
}

# Function to copy file to remote server
copy_to_server() {
    local name="$1"
    local local_file="$2"
    local remote_path="$3"
    
    if [[ -z "$name" || -z "$local_file" ]]; then
        echo -e "${RED}Connection name and local file are required${NC}"
        log "File copy failed: Connection name and local file are required" "ERROR"
        return 1
    fi
    
    # Set default remote path if not provided
    if [[ -z "$remote_path" ]]; then
        remote_path="~/"
    fi
    
    # Check if connection exists
    if [[ ! -f "$CONFIG_DIR/conn_$name.conf" ]]; then
        echo -e "${RED}Connection not found: $name${NC}"
        log "Connection not found: $name" "ERROR"
        return 1
    fi
    
    # Check if local file exists
    if [[ ! -f "$local_file" ]]; then
        echo -e "${RED}Local file not found: $local_file${NC}"
        log "Local file not found: $local_file" "ERROR"
        return 1
    fi
    
    # Load connection configuration
    source "$CONFIG_DIR/conn_$name.conf"
    
    # Copy file to remote server
    echo -e "${YELLOW}Copying file to remote server: $local_file -> $USER@$HOST:$remote_path${NC}"
    log "Copying file to remote server: $local_file -> $USER@$HOST:$remote_path"
    
    if [[ -n "$KEY" && -f "$CONFIG_DIR/$KEY" ]]; then
        scp -i "$CONFIG_DIR/$KEY" -P "$PORT" "$local_file" "$USER@$HOST:$remote_path"
    else
        scp -P "$PORT" "$local_file" "$USER@$HOST:$remote_path"
    fi
    
    # Check copy status
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}File copied successfully: $local_file -> $USER@$HOST:$remote_path${NC}"
        log "File copied successfully: $local_file -> $USER@$HOST:$remote_path"
        return 0
    else
        echo -e "${RED}File copy failed: $local_file -> $USER@$HOST:$remote_path${NC}"
        log "File copy failed: $local_file -> $USER@$HOST:$remote_path" "ERROR"
        return 1
    fi
}

# Function to copy file from remote server
copy_from_server() {
    local name="$1"
    local remote_file="$2"
    local local_path="$3"
    
    if [[ -z "$name" || -z "$remote_file" ]]; then
        echo -e "${RED}Connection name and remote file are required${NC}"
        log "File copy failed: Connection name and remote file are required" "ERROR"
        return 1
    fi
    
    # Set default local path if not provided
    if [[ -z "$local_path" ]]; then
        local_path="."
    fi
    
    # Check if connection exists
    if [[ ! -f "$CONFIG_DIR/conn_$name.conf" ]]; then
        echo -e "${RED}Connection not found: $name${NC}"
        log "Connection not found: $name" "ERROR"
        return 1
    fi
    
    # Check if local path exists
    if [[ ! -d "$local_path" ]]; then
        echo -e "${RED}Local path not found: $local_path${NC}"
        log "Local path not found: $local_path" "ERROR"
        return 1
    fi
    
    # Load connection configuration
    source "$CONFIG_DIR/conn_$name.conf"
    
    # Copy file from remote server
    echo -e "${YELLOW}Copying file from remote server: $USER@$HOST:$remote_file -> $local_path${NC}"
    log "Copying file from remote server: $USER@$HOST:$remote_file -> $local_path"
    
    if [[ -n "$KEY" && -f "$CONFIG_DIR/$KEY" ]]; then
        scp -i "$CONFIG_DIR/$KEY" -P "$PORT" "$USER@$HOST:$remote_file" "$local_path"
    else
        scp -P "$PORT" "$USER@$HOST:$remote_file" "$local_path"
    fi
    
    # Check copy status
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}File copied successfully: $USER@$HOST:$remote_file -> $local_path${NC}"
        log "File copied successfully: $USER@$HOST:$remote_file -> $local_path"
        return 0
    else
        echo -e "${RED}File copy failed: $USER@$HOST:$remote_file -> $local_path${NC}"
        log "File copy failed: $USER@$HOST:$remote_file -> $local_path" "ERROR"
        return 1
    fi
}

# Function to execute command on remote server
execute_command() {
    local name="$1"
    local command="$2"
    
    if [[ -z "$name" || -z "$command" ]]; then
        echo -e "${RED}Connection name and command are required${NC}"
        log "Command execution failed: Connection name and command are required" "ERROR"
        return 1
    fi
    
    # Check if connection exists
    if [[ ! -f "$CONFIG_DIR/conn_$name.conf" ]]; then
        echo -e "${RED}Connection not found: $name${NC}"
        log "Connection not found: $name" "ERROR"
        return 1
    fi
    
    # Load connection configuration
    source "$CONFIG_DIR/conn_$name.conf"
    
    # Execute command on remote server
    echo -e "${YELLOW}Executing command on remote server: $USER@$HOST:$PORT${NC}"
    echo -e "${CYAN}Command: $command${NC}"
    log "Executing command on remote server: $USER@$HOST:$PORT"
    log "Command: $command"
    
    if [[ -n "$KEY" && -f "$CONFIG_DIR/$KEY" ]]; then
        ssh -i "$CONFIG_DIR/$KEY" -p "$PORT" "$USER@$HOST" "$command"
    else
        ssh -p "$PORT" "$USER@$HOST" "$command"
    fi
    
    # Check execution status
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Command executed successfully: $command${NC}"
        log "Command executed successfully: $command"
        return 0
    else
        echo -e "${RED}Command execution failed: $command${NC}"
        log "Command execution failed: $command" "ERROR"
        return 1
    fi
}

# Function to display help
display_help() {
    echo -e "${CYAN}Usage: $0 [command] [options]${NC}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}add <name> <host> [user] [port] [key] [password]${NC}  Add SSH connection"
    echo -e "  ${GREEN}list${NC}                                              List SSH connections"
    echo -e "  ${GREEN}connect <name>${NC}                                    Connect to SSH server"
    echo -e "  ${GREEN}delete <name>${NC}                                     Delete SSH connection"
    echo -e "  ${GREEN}edit <name> <field> <value>${NC}                       Edit SSH connection"
    echo -e "  ${GREEN}test <name>${NC}                                       Test SSH connection"
    echo -e "  ${GREEN}copy-to <name> <local_file> [remote_path]${NC}         Copy file to remote server"
    echo -e "  ${GREEN}copy-from <name> <remote_file> [local_path]${NC}       Copy file from remote server"
    echo -e "  ${GREEN}exec <name> <command>${NC}                             Execute command on remote server"
    echo -e "  ${GREEN}help${NC}                                              Display this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$0 add server1 192.168.1.100 root 22 my_key${NC}       Add SSH connection"
    echo -e "  ${GREEN}$0 list${NC}                                           List SSH connections"
    echo -e "  ${GREEN}$0 connect server1${NC}                                Connect to SSH server"
    echo -e "  ${GREEN}$0 delete server1${NC}                                 Delete SSH connection"
    echo -e "  ${GREEN}$0 edit server1 PORT 2222${NC}                         Edit SSH connection"
    echo -e "  ${GREEN}$0 test server1${NC}                                   Test SSH connection"
    echo -e "  ${GREEN}$0 copy-to server1 file.txt /home/user/${NC}           Copy file to remote server"
    echo -e "  ${GREEN}$0 copy-from server1 /home/user/file.txt ./${NC}       Copy file from remote server"
    echo -e "  ${GREEN}$0 exec server1 \"ls -la\"${NC}                          Execute command on remote server"
    echo ""
}

# Main function
main() {
    # Create directories if they don't exist
    mkdir -p "$CONFIG_DIR" "$LOGS_DIR"
    
    # Parse command line arguments
    local command="$1"
    shift
    
    case "$command" in
        "add")
            add_connection "$@"
            ;;
        "list")
            list_connections
            ;;
        "connect")
            connect_to_server "$@"
            ;;
        "delete")
            delete_connection "$@"
            ;;
        "edit")
            edit_connection "$@"
            ;;
        "test")
            test_connection "$@"
            ;;
        "copy-to")
            copy_to_server "$@"
            ;;
        "copy-from")
            copy_from_server "$@"
            ;;
        "exec")
            execute_command "$@"
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