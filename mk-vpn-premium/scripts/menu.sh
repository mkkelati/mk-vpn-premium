#!/bin/bash
#
# MK VPN Premium - Menu Functions
# Version: 1.0.0
# Author: MK VPN Premium Team
#

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PARENT_DIR/config"
LOGS_DIR="$PARENT_DIR/logs"

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
    read -p "Tunnel Type (local/remote/dynamic) : " type
    read -p "Local Port : " local_port
    read -p "Remote Host : " remote_host
    read -p "Remote Port : " remote_port
    read -p "SSH Host : " ssh_host
    read -p "SSH User [root] : " ssh_user
    ssh_user=${ssh_user:-root}
    read -p "SSH Port [22] : " ssh_port
    ssh_port=${ssh_port:-22}
    
    "$SCRIPT_DIR/tunnel_manager.sh" create "$type" "$name" "$local_port" "$remote_host" "$remote_port" "$ssh_host" "$ssh_user" "$ssh_port"
    read -n 1 -s -r -p "Press any key to continue"
}

delete_ssh_tunnel() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              DELETE SSH TUNNEL                    ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -p "Tunnel Name : " name
    "$SCRIPT_DIR/tunnel_manager.sh" delete "$name"
    read -n 1 -s -r -p "Press any key to continue"
}

check_ssh_tunnels() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SSH TUNNEL LIST                      ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    "$SCRIPT_DIR/tunnel_manager.sh" list
    read -n 1 -s -r -p "Press any key to continue"
}

# Proxy Management Functions
setup_squid_proxy() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP SQUID PROXY                    ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get update -y
    apt-get install -y squid
    
    # Backup original config
    cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
    
    # Create new config
    cat > /etc/squid/squid.conf << EOF
# MK VPN Premium Squid Configuration
http_port 3128
http_port 8080
http_port 8000
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
http_access allow all
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname MK-VPN-Premium
EOF
    
    systemctl restart squid
    systemctl enable squid
    
    echo -e "${GREEN}Squid Proxy has been installed and configured${NC}"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    echo -e "Proxy Ports: 3128, 8080, 8000"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_socks5_proxy() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP SOCKS5 PROXY                   ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get update -y
    apt-get install -y dante-server
    
    # Backup original config if exists
    if [ -f /etc/danted.conf ]; then
        cp /etc/danted.conf /etc/danted.conf.bak
    fi
    
    # Create new config
    cat > /etc/danted.conf << EOF
logoutput: /var/log/danted.log
internal: 0.0.0.0 port=1080
external: eth0
socksmethod: username none
clientmethod: none
user.privileged: root
user.unprivileged: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
EOF
    
    systemctl restart danted
    systemctl enable danted
    
    echo -e "${GREEN}SOCKS5 Proxy has been installed and configured${NC}"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    echo -e "SOCKS5 Port: 1080"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_http_proxy() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP HTTP PROXY                     ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    apt-get update -y
    apt-get install -y tinyproxy
    
    # Backup original config
    cp /etc/tinyproxy/tinyproxy.conf /etc/tinyproxy/tinyproxy.conf.bak
    
    # Create new config
    cat > /etc/tinyproxy/tinyproxy.conf << EOF
User nobody
Group nogroup
Port 8888
Timeout 600
DefaultErrorFile "/usr/share/tinyproxy/default.html"
StatFile "/usr/share/tinyproxy/stats.html"
LogFile "/var/log/tinyproxy/tinyproxy.log"
LogLevel Info
PidFile "/run/tinyproxy/tinyproxy.pid"
MaxClients 100
MinSpareServers 5
MaxSpareServers 20
StartServers 10
MaxRequestsPerChild 0
Allow 127.0.0.1
Allow 0.0.0.0/0
ViaProxyName "MK-VPN-Premium"
ConnectPort 443
ConnectPort 563
EOF
    
    systemctl restart tinyproxy
    systemctl enable tinyproxy
    
    echo -e "${GREEN}HTTP Proxy has been installed and configured${NC}"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    echo -e "HTTP Proxy Port: 8888"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

# VPN Management Functions
setup_openvpn() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP OPENVPN                        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    
    # Install OpenVPN
    apt-get update -y
    apt-get install -y openvpn easy-rsa
    
    # Setup OpenVPN server
    mkdir -p /etc/openvpn/easy-rsa
    cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
    
    echo -e "${YELLOW}Setting up OpenVPN server...${NC}"
    echo -e "${GREEN}OpenVPN has been installed${NC}"
    echo -e "${YELLOW}For complete setup, please run the OpenVPN setup script manually${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_wireguard() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP WIREGUARD                      ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    
    # Install WireGuard
    apt-get update -y
    apt-get install -y wireguard
    
    echo -e "${GREEN}WireGuard has been installed${NC}"
    echo -e "${YELLOW}For complete setup, please run the WireGuard setup script manually${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_ikev2() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP IKEV2                          ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    
    # Install StrongSwan
    apt-get update -y
    apt-get install -y strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins libstrongswan-extra-plugins
    
    echo -e "${GREEN}IKEv2 (strongSwan) has been installed${NC}"
    echo -e "${YELLOW}For complete setup, please run the IKEv2 setup script manually${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

# Extra Tools Functions
setup_stunnel() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP STUNNEL                        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    
    # Install STunnel
    apt-get update -y
    apt-get install -y stunnel4
    
    # Create certificate
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=MK-VPN-Premium" \
    -keyout /etc/stunnel/stunnel.key -out /etc/stunnel/stunnel.crt
    
    # Combine key and cert
    cat /etc/stunnel/stunnel.key /etc/stunnel/stunnel.crt > /etc/stunnel/stunnel.pem
    
    # Create config
    cat > /etc/stunnel/stunnel.conf << EOF
cert = /etc/stunnel/stunnel.pem
client = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ssh]
accept = 443
connect = 127.0.0.1:22

[dropbear]
accept = 444
connect = 127.0.0.1:80

[openvpn]
accept = 445
connect = 127.0.0.1:1194
EOF
    
    # Enable stunnel service
    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
    systemctl restart stunnel4
    systemctl enable stunnel4
    
    echo -e "${GREEN}STunnel has been installed and configured${NC}"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    echo -e "SSH over SSL Port: 443"
    echo -e "Dropbear over SSL Port: 444"
    echo -e "OpenVPN over SSL Port: 445"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_badvpn() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP BADVPN                         ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    
    # Install dependencies
    apt-get update -y
    apt-get install -y cmake make gcc g++ screen
    
    # Download and install BadVPN
    cd /usr/local/src/
    wget -O badvpn.zip https://github.com/ambrop72/badvpn/archive/refs/heads/master.zip
    unzip -o badvpn.zip
    cd badvpn-master
    mkdir -p build
    cd build
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
    make install
    
    # Create systemd service
    cat > /etc/systemd/system/badvpn.service << EOF
[Unit]
Description=BadVPN UDPGW Service
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start service
    systemctl enable badvpn
    systemctl start badvpn
    
    echo -e "${GREEN}BadVPN has been installed and configured${NC}"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    echo -e "BadVPN UDP Gateway Port: 7300"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_cloudflare_ws() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP CLOUDFLARE WS                  ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    
    # Install dependencies
    apt-get update -y
    apt-get install -y python3 python3-pip
    pip3 install websockets
    
    # Create WebSocket script
    mkdir -p "$PARENT_DIR/websocket"
    cat > "$PARENT_DIR/websocket/ws.py" << EOF
#!/usr/bin/env python3
import asyncio
import websockets
import socket
import ssl
import argparse

async def handle_connection(websocket, path):
    try:
        remote_host, remote_port = path.lstrip('/').split(':')
        remote_port = int(remote_port)
        
        reader, writer = await asyncio.open_connection(remote_host, remote_port)
        
        async def forward_to_socket():
            try:
                while True:
                    data = await websocket.recv()
                    writer.write(data)
                    await writer.drain()
            except Exception as e:
                print(f"Error forwarding to socket: {e}")
                writer.close()
                
        async def forward_to_websocket():
            try:
                while True:
                    data = await reader.read(4096)
                    if not data:
                        break
                    await websocket.send(data)
            except Exception as e:
                print(f"Error forwarding to websocket: {e}")
                await websocket.close()
                
        await asyncio.gather(
            forward_to_socket(),
            forward_to_websocket()
        )
    except Exception as e:
        print(f"Connection error: {e}")

async def main(host, port, cert_path=None, key_path=None):
    if cert_path and key_path:
        ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ssl_context.load_cert_chain(cert_path, key_path)
    else:
        ssl_context = None
        
    server = await websockets.serve(
        handle_connection, 
        host, 
        port, 
        ssl=ssl_context
    )
    
    print(f"WebSocket server started on {host}:{port}")
    await server.wait_closed()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='WebSocket to TCP proxy')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind')
    parser.add_argument('--port', type=int, default=8880, help='Port to bind')
    parser.add_argument('--cert', help='SSL certificate path')
    parser.add_argument('--key', help='SSL key path')
    
    args = parser.parse_args()
    
    asyncio.run(main(args.host, args.port, args.cert, args.key))
EOF
    
    # Make script executable
    chmod +x "$PARENT_DIR/websocket/ws.py"
    
    # Create systemd service
    cat > /etc/systemd/system/websocket.service << EOF
[Unit]
Description=WebSocket Proxy Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 $PARENT_DIR/websocket/ws.py --port 8880
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start service
    systemctl enable websocket
    systemctl start websocket
    
    echo -e "${GREEN}Cloudflare WebSocket has been installed and configured${NC}"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    echo -e "WebSocket Port: 8880"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

setup_udpgw() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              SETUP UDPGW                          ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    
    # Start BadVPN UDP Gateway in screen
    screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300
    
    echo -e "${GREEN}UDPGW has been started${NC}"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    echo -e "UDPGW Port: 7300"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
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
    echo -e "System Load  : $(uptime | awk -F'load average:' '{print $2}' | sed 's/,//g')"
    echo -e "Uptime       : $(uptime -p)"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              NETWORK STATUS                       ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "IP Address   : $(curl -s ifconfig.me)"
    echo -e "SSH Service  : $(systemctl is-active sshd)"
    echo -e "Squid Proxy  : $(systemctl is-active squid 2>/dev/null || echo "not installed")"
    echo -e "OpenVPN      : $(systemctl is-active openvpn 2>/dev/null || echo "not installed")"
    echo -e "STunnel      : $(systemctl is-active stunnel4 2>/dev/null || echo "not installed")"
    echo -e "BadVPN       : $(systemctl is-active badvpn 2>/dev/null || echo "not installed")"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

check_port_status() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              PORT STATUS                          ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}LISTENING PORTS:${NC}"
    netstat -tulpn | grep LISTEN
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}ESTABLISHED CONNECTIONS:${NC}"
    netstat -tn | grep ESTABLISHED
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

backup_users() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              BACKUP USERS                         ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    backup_file="/root/user_backup_$(date +%Y%m%d).tar.gz"
    tar -czf $backup_file /etc/passwd /etc/shadow /etc/group /etc/gshadow
    echo -e "${GREEN}Backup created: $backup_file${NC}"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    echo -e "Backup File: $backup_file"
    echo -e "${WHITE}═══════════════════════════════════════${NC}"
    read -n 1 -s -r -p "Press any key to continue"
}

restore_users() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              RESTORE USERS                        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    read -p "Enter backup file path: " backup_file
    if [ -f "$backup_file" ]; then
        tar -xzf $backup_file -C /
        echo -e "${GREEN}Users restored from backup${NC}"
    else
        echo -e "${RED}Backup file not found: $backup_file${NC}"
    fi
    read -n 1 -s -r -p "Press any key to continue"
} 