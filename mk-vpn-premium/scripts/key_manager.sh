#!/bin/bash
#
# MK VPN Premium - SSH Key Manager
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
LOG_FILE="$LOGS_DIR/key_manager-$(date +%Y-%m-%d).log"

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
    echo -e "${GREEN}                   SSH KEY MANAGER                             ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${YELLOW}                    Version 1.0.0                             ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

# Function to generate SSH key
generate_key() {
    local key_name="$1"
    local key_type="${2:-rsa}"
    local key_bits="${3:-4096}"
    local passphrase="${4:-}"
    
    if [[ -z "$key_name" ]]; then
        echo -e "${RED}Key name is required${NC}"
        log "Key generation failed: Key name is required" "ERROR"
        return 1
    fi
    
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    # Generate SSH key
    echo -e "${YELLOW}Generating SSH key: $key_name (type: $key_type, bits: $key_bits)${NC}"
    log "Generating SSH key: $key_name (type: $key_type, bits: $key_bits)"
    
    if [[ -z "$passphrase" ]]; then
        ssh-keygen -t "$key_type" -b "$key_bits" -f "$CONFIG_DIR/$key_name" -N ""
    else
        ssh-keygen -t "$key_type" -b "$key_bits" -f "$CONFIG_DIR/$key_name" -N "$passphrase"
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SSH key generated successfully: $CONFIG_DIR/$key_name${NC}"
        log "SSH key generated successfully: $CONFIG_DIR/$key_name"
        
        # Display public key
        echo -e "${YELLOW}Public key:${NC}"
        cat "$CONFIG_DIR/$key_name.pub"
        
        return 0
    else
        echo -e "${RED}Failed to generate SSH key${NC}"
        log "Failed to generate SSH key" "ERROR"
        return 1
    fi
}

# Function to list SSH keys
list_keys() {
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    echo -e "${YELLOW}Available SSH keys:${NC}"
    log "Listing SSH keys"
    
    # Check if there are any keys
    if [[ ! -f "$CONFIG_DIR"/*.pub ]]; then
        echo -e "${CYAN}No SSH keys found${NC}"
        return 0
    fi
    
    # List keys
    find "$CONFIG_DIR" -name "*.pub" | while read -r key; do
        base_key=$(basename "$key" .pub)
        key_type=$(ssh-keygen -l -f "$key" | awk '{print $4}')
        key_bits=$(ssh-keygen -l -f "$key" | awk '{print $1}')
        key_fingerprint=$(ssh-keygen -l -f "$key" | awk '{print $2}')
        
        echo -e "${GREEN}- $base_key${NC} (type: $key_type, bits: $key_bits)"
        echo -e "  Fingerprint: $key_fingerprint"
    done
    
    return 0
}

# Function to delete SSH key
delete_key() {
    local key_name="$1"
    
    if [[ -z "$key_name" ]]; then
        echo -e "${RED}Key name is required${NC}"
        log "Key deletion failed: Key name is required" "ERROR"
        return 1
    fi
    
    # Check if key exists
    if [[ ! -f "$CONFIG_DIR/$key_name" ]]; then
        echo -e "${RED}SSH key not found: $key_name${NC}"
        log "SSH key not found: $key_name" "ERROR"
        return 1
    fi
    
    # Delete key
    echo -e "${YELLOW}Deleting SSH key: $key_name${NC}"
    log "Deleting SSH key: $key_name"
    
    rm -f "$CONFIG_DIR/$key_name" "$CONFIG_DIR/$key_name.pub"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SSH key deleted successfully: $key_name${NC}"
        log "SSH key deleted successfully: $key_name"
        return 0
    else
        echo -e "${RED}Failed to delete SSH key: $key_name${NC}"
        log "Failed to delete SSH key: $key_name" "ERROR"
        return 1
    fi
}

# Function to import SSH key
import_key() {
    local key_name="$1"
    local key_file="$2"
    
    if [[ -z "$key_name" || -z "$key_file" ]]; then
        echo -e "${RED}Key name and key file are required${NC}"
        log "Key import failed: Key name and key file are required" "ERROR"
        return 1
    fi
    
    # Check if key file exists
    if [[ ! -f "$key_file" ]]; then
        echo -e "${RED}Key file not found: $key_file${NC}"
        log "Key file not found: $key_file" "ERROR"
        return 1
    fi
    
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    # Import key
    echo -e "${YELLOW}Importing SSH key: $key_name${NC}"
    log "Importing SSH key: $key_name"
    
    cp "$key_file" "$CONFIG_DIR/$key_name"
    
    # Check if public key exists
    if [[ -f "$key_file.pub" ]]; then
        cp "$key_file.pub" "$CONFIG_DIR/$key_name.pub"
    else
        # Generate public key
        ssh-keygen -y -f "$CONFIG_DIR/$key_name" > "$CONFIG_DIR/$key_name.pub"
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SSH key imported successfully: $key_name${NC}"
        log "SSH key imported successfully: $key_name"
        return 0
    else
        echo -e "${RED}Failed to import SSH key: $key_name${NC}"
        log "Failed to import SSH key: $key_name" "ERROR"
        return 1
    fi
}

# Function to export SSH key
export_key() {
    local key_name="$1"
    local export_dir="$2"
    
    if [[ -z "$key_name" ]]; then
        echo -e "${RED}Key name is required${NC}"
        log "Key export failed: Key name is required" "ERROR"
        return 1
    fi
    
    # Set default export directory
    if [[ -z "$export_dir" ]]; then
        export_dir="$HOME"
    fi
    
    # Check if key exists
    if [[ ! -f "$CONFIG_DIR/$key_name" ]]; then
        echo -e "${RED}SSH key not found: $key_name${NC}"
        log "SSH key not found: $key_name" "ERROR"
        return 1
    fi
    
    # Check if export directory exists
    if [[ ! -d "$export_dir" ]]; then
        echo -e "${RED}Export directory not found: $export_dir${NC}"
        log "Export directory not found: $export_dir" "ERROR"
        return 1
    fi
    
    # Export key
    echo -e "${YELLOW}Exporting SSH key: $key_name${NC}"
    log "Exporting SSH key: $key_name"
    
    cp "$CONFIG_DIR/$key_name" "$export_dir/$key_name"
    cp "$CONFIG_DIR/$key_name.pub" "$export_dir/$key_name.pub"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SSH key exported successfully: $export_dir/$key_name${NC}"
        log "SSH key exported successfully: $export_dir/$key_name"
        return 0
    else
        echo -e "${RED}Failed to export SSH key: $key_name${NC}"
        log "Failed to export SSH key: $key_name" "ERROR"
        return 1
    fi
}

# Function to display help
display_help() {
    echo -e "${CYAN}Usage: $0 [command] [options]${NC}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}generate <name> [type] [bits] [passphrase]${NC}  Generate SSH key"
    echo -e "  ${GREEN}list${NC}                                        List SSH keys"
    echo -e "  ${GREEN}delete <name>${NC}                               Delete SSH key"
    echo -e "  ${GREEN}import <name> <file>${NC}                        Import SSH key"
    echo -e "  ${GREEN}export <name> [directory]${NC}                   Export SSH key"
    echo -e "  ${GREEN}help${NC}                                        Display this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${GREEN}$0 generate my_key${NC}                          Generate RSA 4096-bit SSH key"
    echo -e "  ${GREEN}$0 generate my_key ed25519${NC}                  Generate Ed25519 SSH key"
    echo -e "  ${GREEN}$0 list${NC}                                     List all SSH keys"
    echo -e "  ${GREEN}$0 delete my_key${NC}                            Delete SSH key"
    echo -e "  ${GREEN}$0 import my_key /path/to/key${NC}               Import SSH key"
    echo -e "  ${GREEN}$0 export my_key /path/to/export${NC}            Export SSH key"
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
        "generate")
            generate_key "$@"
            ;;
        "list")
            list_keys
            ;;
        "delete")
            delete_key "$@"
            ;;
        "import")
            import_key "$@"
            ;;
        "export")
            export_key "$@"
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