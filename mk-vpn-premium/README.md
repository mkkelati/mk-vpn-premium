# MK VPN Premium

A comprehensive SSH, Tunnel, Proxy, and VPN management solution for Ubuntu servers.

## Features

- SSH User Management
- SSH Tunnel Management
- Proxy Server Setup (Squid, SOCKS5, HTTP)
- VPN Server Setup (OpenVPN, WireGuard, IKEv2)
- Extra Tools (STunnel, BadVPN, Cloudflare WebSocket, UDPGW)
- System Monitoring Tools

## Requirements

- Ubuntu 20.04 or higher
- Root access
- Internet connection

## Quick Installation

Use our one-line installation command:

```bash
curl -s https://raw.githubusercontent.com/mkkelati/mk-vpn-premium/main/one-line-install.sh | bash
```

Or with wget:

```bash
wget -O - https://raw.githubusercontent.com/mkkelati/mk-vpn-premium/main/one-line-install.sh | bash
```

## Manual Installation

If you prefer to install manually:

```bash
# Update system
apt-get update -y
apt-get upgrade -y

# Install git
apt-get install -y git

# Clone repository
git clone https://github.com/mkkelati/mk-vpn-premium.git /root/mk-vpn-premium

# Make scripts executable
chmod +x /root/mk-vpn-premium/mk-vpn.sh
chmod +x /root/mk-vpn-premium/install.sh
chmod +x /root/mk-vpn-premium/direct-install.sh
chmod +x /root/mk-vpn-premium/scripts/*.sh

# Run installation script
cd /root/mk-vpn-premium
./direct-install.sh
```

## Usage

After installation, you can access MK VPN Premium by running:

```bash
mk-vpn
```

This will display the main menu with all available options.

## SSH Management

- Create SSH User: Create a new SSH user with password authentication
- Delete SSH User: Remove an existing SSH user
- Renew SSH User: Extend the expiration date of an SSH user
- Check SSH Users: List all SSH users with their expiration dates

## Tunnel Management

- Create SSH Tunnel: Set up a new SSH tunnel (local, remote, or dynamic)
- Delete SSH Tunnel: Remove an existing SSH tunnel
- Check SSH Tunnels: List all configured SSH tunnels

## Proxy Management

- Setup Squid Proxy: Install and configure Squid proxy server
- Setup SOCKS5 Proxy: Install and configure SOCKS5 proxy server
- Setup HTTP Proxy: Install and configure HTTP proxy server

## VPN Management

- Setup OpenVPN: Install and configure OpenVPN server
- Setup WireGuard: Install and configure WireGuard VPN server
- Setup IKEv2: Install and configure IKEv2/IPsec VPN server

## Extra Tools

- Setup STunnel: Install and configure STunnel for SSL tunneling
- Setup BadVPN: Install and configure BadVPN for UDP forwarding
- Setup Cloudflare WS: Install and configure Cloudflare WebSocket proxy
- Setup UDPGW: Set up UDP Gateway for improved UDP performance

## System Tools

- Check System Status: Display system resource usage and service status
- Check Port Status: List all open ports and established connections
- Backup Users: Create a backup of all user accounts
- Restore Users: Restore user accounts from a backup

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue on GitHub or contact the MK VPN Premium Team. 