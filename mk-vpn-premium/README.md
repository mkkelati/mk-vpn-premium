# MK VPN Premium - SSH Script Manager

MK VPN Premium is a professional SSH script manager designed for Ubuntu 20.04 and above. It provides a comprehensive set of tools for managing SSH connections, keys, tunnels, and server configurations.

## Features

- **SSH Key Management**: Generate, list, and delete SSH keys
- **SSH Connection Management**: Add, list, connect to, and delete SSH connections
- **SSH Server Management**: Configure and manage SSH server settings
- **SSH Tunnel Management**: Create and manage local, remote, and dynamic SSH tunnels
- **Security Features**: Integrated firewall and fail2ban setup
- **Backup and Restore**: Backup and restore SSH configurations

## Installation

### Prerequisites

- Ubuntu 20.04 or higher
- Root access
- Installation key: `457251`

### Installation Steps

1. Download the installation package:

```bash
git clone https://github.com/yourusername/mk-vpn-premium.git
cd mk-vpn-premium
```

2. Make the installation script executable:

```bash
chmod +x install.sh
```

3. Run the installation script:

```bash
sudo ./install.sh
```

4. Enter the installation key when prompted: `457251`

5. After installation, you can use the `mk-vpn` command from anywhere in the system.

## Usage

### Basic Commands

```bash
# Display help
mk-vpn help

# Install MK VPN Premium
mk-vpn install 457251

# Uninstall MK VPN Premium
mk-vpn uninstall
```

### SSH Key Management

```bash
# Generate SSH key
mk-vpn key generate my_key

# List SSH keys
mk-vpn key list

# Delete SSH key
mk-vpn key delete my_key
```

### SSH Connection Management

```bash
# Add SSH connection
mk-vpn conn add server1 192.168.1.100 root 22 my_key

# List SSH connections
mk-vpn conn list

# Connect to SSH server
mk-vpn conn connect server1

# Delete SSH connection
mk-vpn conn delete server1
```

### SSH Server Management

```bash
# Display SSH server status
mk-vpn server status

# Start SSH server
mk-vpn server start

# Stop SSH server
mk-vpn server stop

# Restart SSH server
mk-vpn server restart

# Configure SSH server
mk-vpn server config
```

### SSH Tunnel Management

```bash
# Create local SSH tunnel
mk-vpn tunnel create local proxy 8080 example.com 80 server1

# Create remote SSH tunnel
mk-vpn tunnel create remote proxy 8080 localhost 80 server1

# Create dynamic SSH tunnel (SOCKS proxy)
mk-vpn tunnel create dynamic proxy 8080 - - server1

# List SSH tunnels
mk-vpn tunnel list

# Start SSH tunnel
mk-vpn tunnel start proxy

# Stop SSH tunnel
mk-vpn tunnel stop proxy

# Delete SSH tunnel
mk-vpn tunnel delete proxy
```

### Backup and Restore

```bash
# Backup SSH configuration
mk-vpn backup

# Restore SSH configuration
mk-vpn restore /path/to/backup/file.tar.gz
```

## Uploading to GitHub

To upload MK VPN Premium to GitHub, follow these steps:

1. Create a new repository on GitHub:
   - Go to [GitHub](https://github.com/)
   - Click on the "+" icon in the top right corner and select "New repository"
   - Enter "mk-vpn-premium" as the repository name
   - Choose whether to make it public or private
   - Click "Create repository"

2. Initialize Git in your local project directory:

```bash
cd mk-vpn-premium
git init
```

3. Add all files to Git:

```bash
git add .
```

4. Commit the changes:

```bash
git commit -m "Initial commit of MK VPN Premium"
```

5. Add the GitHub repository as a remote:

```bash
git remote add origin https://github.com/yourusername/mk-vpn-premium.git
```

6. Push the code to GitHub:

```bash
git push -u origin master
```

7. Your code is now available on GitHub at `https://github.com/yourusername/mk-vpn-premium`

## Installing on a Server

To install MK VPN Premium on any Ubuntu server (version 20.04 or higher), follow these steps:

1. Connect to your server via SSH:

```bash
ssh user@your-server-ip
```

2. Clone the repository:

```bash
git clone https://github.com/yourusername/mk-vpn-premium.git
cd mk-vpn-premium
```

3. Make the installation script executable:

```bash
chmod +x install.sh
```

4. Run the installation script:

```bash
sudo ./install.sh
```

5. Enter the installation key when prompted: `457251`

6. After installation, you can use the `mk-vpn` command from anywhere in the system.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

MK VPN Premium Team 