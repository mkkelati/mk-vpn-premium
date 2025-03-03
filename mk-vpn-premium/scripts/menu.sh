#!/bin/bash
#
# MK VPN Premium - Menu Functions
# Version: 1.0.0
# Author: MK VPN Premium Team
#

# SSH Management Functions
create_ssh_user() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              CREATE SSH USER                      ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -p "Username : " username
    read -p "Password : " password
    read -p "Duration (days) : " duration
    useradd -M -N -s /bin/false -e $(date -d "+$duration days" +"%Y-%m-%d") $username
    echo -e "$password\n$password" | passwd $username > /dev/null 2>&1
    echo -e "${GREEN}SSH Account Created Successfully${NC}"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    echo -e "Username   : $username"
    echo -e "Password   : $password"
    echo -e "Duration   : $duration days"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

delete_ssh_user() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              DELETE SSH USER                      ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -p "Username : " username
    userdel -f $username > /dev/null 2>&1
    echo -e "${GREEN}User $username has been deleted${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

renew_ssh_user() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              RENEW SSH USER                       ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -p "Username : " username
    read -p "Duration to add (days) : " duration
    chage -E $(date -d "+$duration days" +"%Y-%m-%d") $username
    echo -e "${GREEN}Account $username has been renewed for $duration days${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

check_ssh_users() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SSH USER LIST                        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}USERNAME          EXP DATE          STATUS        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    while read expired
    do
        AKUN="$(echo $expired | cut -d: -f1)"
        ID="$(echo $expired | grep -v nobody | cut -d: -f3)"
        exp="$(chage -l $AKUN | grep "Account expires" | awk -F": " '{print $2}')"
        status="$(passwd -S $AKUN | awk '{print $2}')"
        if [[ $ID -ge 1000 ]]; then
            printf "%-17s %2s %-17s %2s %-7s\n" "$AKUN" "" "$exp" "" "$status"
        fi
    done < /etc/passwd
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

# Tunnel Management Functions
create_ssh_tunnel() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              CREATE SSH TUNNEL                    ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -p "Tunnel Name : " name
    read -p "Local Port : " local_port
    read -p "Remote Host : " remote_host
    read -p "Remote Port : " remote_port
    /root/mk-vpn-premium/scripts/tunnel_manager.sh create $name $local_port $remote_host $remote_port
    read -n 1 -s -r -p "Press any key to continue"
}

delete_ssh_tunnel() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              DELETE SSH TUNNEL                    ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -p "Tunnel Name : " name
    /root/mk-vpn-premium/scripts/tunnel_manager.sh delete $name
    read -n 1 -s -r -p "Press any key to continue"
}

check_ssh_tunnels() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SSH TUNNEL LIST                      ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    /root/mk-vpn-premium/scripts/tunnel_manager.sh list
    read -n 1 -s -r -p "Press any key to continue"
}

# Proxy Management Functions
setup_squid_proxy() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP SQUID PROXY                    ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get install -y squid
    systemctl enable squid
    systemctl start squid
    echo -e "${GREEN}Squid Proxy has been installed and started${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_socks5_proxy() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP SOCKS5 PROXY                   ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get install -y dante-server
    systemctl enable danted
    systemctl start danted
    echo -e "${GREEN}SOCKS5 Proxy has been installed and started${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_http_proxy() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP HTTP PROXY                     ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get install -y tinyproxy
    systemctl enable tinyproxy
    systemctl start tinyproxy
    echo -e "${GREEN}HTTP Proxy has been installed and started${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

# VPN Management Functions
setup_openvpn() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP OPENVPN                        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get install -y openvpn
    echo -e "${GREEN}OpenVPN has been installed${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_wireguard() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP WIREGUARD                      ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get install -y wireguard
    echo -e "${GREEN}WireGuard has been installed${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_ikev2() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP IKEV2                          ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get install -y strongswan
    echo -e "${GREEN}IKEv2 (strongSwan) has been installed${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

# Extra Tools Functions
setup_stunnel() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP STUNNEL                        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get install -y stunnel4
    echo -e "${GREEN}STunnel has been installed${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_badvpn() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP BADVPN                         ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64"
    chmod +x /usr/bin/badvpn-udpgw
    echo -e "${GREEN}BadVPN has been installed${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_cloudflare_ws() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP CLOUDFLARE WS                  ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get install -y python3 python3-pip
    pip3 install websockets
    echo -e "${GREEN}Cloudflare WebSocket has been installed${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_udpgw() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP UDPGW                          ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300
    echo -e "${GREEN}UDPGW has been started${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

# System Tools Functions
check_system_status() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SYSTEM STATUS                        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "CPU Usage    : $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo -e "Memory Usage : $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
    echo -e "Disk Usage   : $(df -h | awk '$NF=="/"{printf "%s", $5}')"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

check_port_status() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              PORT STATUS                          ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    netstat -tulpn | grep LISTEN
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

backup_users() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              BACKUP USERS                         ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    tar -czf /root/user_backup_$(date +%Y%m%d).tar.gz /etc/passwd /etc/shadow /etc/group
    echo -e "${GREEN}Backup created: /root/user_backup_$(date +%Y%m%d).tar.gz${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

restore_users() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              RESTORE USERS                        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -p "Enter backup file path: " backup_file
    tar -xzf $backup_file -C /
    echo -e "${GREEN}Users restored from backup${NC}"
    read -n 1 -s -r -p "Press any key to continue"
} 