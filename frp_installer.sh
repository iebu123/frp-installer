#!/bin/bash
# Interactive Shell Script for Automated FRP Server (frps) & Client (frpc) Setup

# --- Global Variables ---
FRP_INSTALL_DIR="/usr/local/bin"
FRP_CONFIG_DIR="/etc/frp"
FRP_VERSION="" # Will be determined dynamically

# --- Helper Functions ---

# Function to print messages
print_message() {
    echo "--------------------------------------------------"
    echo "$1"
    echo "--------------------------------------------------"
}

# Function to detect OS and architecture
detect_os_arch() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
    esac

    echo "Detected OS: $OS"
    echo "Detected Architecture: $ARCH"
}

# --- Main Functions ---

# Function to configure frps
configure_server() {
    print_message "Configuring FRP Server (frps)"

    # Prompt for configuration details
    read -p "Enter bind port [default: 7000]: " bindPort
    bindPort=${bindPort:-7000}

    read -p "Enter authentication token: " authToken

    read -p "Enable dashboard? [y/N]: " enableDashboard
    if [[ "$enableDashboard" == "y" || "$enableDashboard" == "Y" ]]; then
        read -p "Enter dashboard port [default: 7500]: " dashboardPort
        dashboardPort=${dashboardPort:-7500}
        read -p "Enter dashboard user: " dashboardUser
        read -s -p "Enter dashboard password: " dashboardPassword
        echo
    fi

    read -p "Enable KCP transport protocol? [y/N]: " enableKcp
    read -p "Enable QUIC transport protocol? [y/N]: " enableQuic

    # Create config directory if it doesn't exist
    sudo mkdir -p "$FRP_CONFIG_DIR"

    # Backup existing config
    if [ -f "${FRP_CONFIG_DIR}/frps.toml" ]; then
        sudo mv "${FRP_CONFIG_DIR}/frps.toml" "${FRP_CONFIG_DIR}/frps.toml.bak"
        echo "Backed up existing frps.toml to frps.toml.bak"
    fi

    # Write new config
    sudo bash -c "cat > ${FRP_CONFIG_DIR}/frps.toml" <<EOL
bindPort = $bindPort
auth.token = "$authToken"
EOL

    if [[ "$enableDashboard" == "y" || "$enableDashboard" == "Y" ]]; then
        sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frps.toml" <<EOL
webServer.port = $dashboardPort
webServer.user = "$dashboardUser"
webServer.password = "$dashboardPassword"
EOL
    fi
    
    if [[ "$enableKcp" == "y" || "$enableKcp" == "Y" ]]; then
        sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frps.toml" <<EOL
transport.kcp.bindPort = $bindPort
EOL
    fi

    if [[ "$enableQuic" == "y" || "$enableQuic" == "Y" ]]; then
        sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frps.toml" <<EOL
transport.quic.bindPort = $bindPort
EOL
    fi

    print_message "frps.toml created successfully!"
}

# Function to configure frpc
configure_client() {
    print_message "Configuring FRP Client (frpc)"

    # Prompt for configuration details
    read -p "Enter server address: " serverAddr
    read -p "Enter server port [default: 7000]: " serverPort
    serverPort=${serverPort:-7000}

    read -p "Enter authentication token: " authToken

    read -p "Enter transport protocol (tcp, kcp, quic) [default: tcp]: " transportProtocol
    transportProtocol=${transportProtocol:-tcp}

    read -p "Enable Admin UI? [y/N]: " enableAdminUI
    if [[ "$enableAdminUI" == "y" || "$enableAdminUI" == "Y" ]]; then
        read -p "Enter Admin UI port [default: 7501]: " adminUIPort
        adminUIPort=${adminUIPort:-7501}
        read -p "Enter Admin UI user: " adminUIUser
        read -s -p "Enter Admin UI password: " adminUIPassword
        echo
    fi

    print_message "Define a proxy"
    read -p "Proxy type (tcp, udp, http, https) [default: tcp]: " proxyType
    proxyType=${proxyType:-tcp}
    read -p "Local IP [default: 127.0.0.1]: " localIP
    localIP=${localIP:-127.0.0.1}
    read -p "Local port: " localPort
    read -p "Remote port: " remotePort

    # Create config directory if it doesn't exist
    sudo mkdir -p "$FRP_CONFIG_DIR"

    # Backup existing config
    if [ -f "${FRP_CONFIG_DIR}/frpc.toml" ]; then
        sudo mv "${FRP_CONFIG_DIR}/frpc.toml" "${FRP_CONFIG_DIR}/frpc.toml.bak"
        echo "Backed up existing frpc.toml to frpc.toml.bak"
    fi

    # Write new config
    sudo bash -c "cat > ${FRP_CONFIG_DIR}/frpc.toml" <<EOL
serverAddr = "$serverAddr"
serverPort = $serverPort
auth.token = "$authToken"
transport.protocol = "$transportProtocol"
EOL

    if [[ "$enableAdminUI" == "y" || "$enableAdminUI" == "Y" ]]; then
        sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frpc.toml" <<EOL
webServer.port = $adminUIPort
webServer.user = "$adminUIUser"
webServer.password = "$adminUIPassword"
EOL
    fi

    sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frpc.toml" <<EOL

[[proxies]]
name = "${proxyType}-proxy"
type = "$proxyType"
localIP = "$localIP"
localPort = $localPort
remotePort = $remotePort
EOL

    print_message "frpc.toml created successfully!"
}

# Function to install or update FRP
install_update_frp() {
    print_message "Installing/Updating FRP"
    detect_os_arch

    # Get the latest version from GitHub
    FRP_VERSION=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c 2-)
    if [ -z "$FRP_VERSION" ]; then
        echo "Error: Could not determine the latest FRP version."
        exit 1
    fi
    echo "Latest FRP version: $FRP_VERSION"

    # Construct download URL
    FRP_FILENAME="frp_${FRP_VERSION}_${OS}_${ARCH}"
    DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FRP_FILENAME}.tar.gz"

    echo "Downloading from: $DOWNLOAD_URL"

    # Download and extract
    curl -L -o "/tmp/${FRP_FILENAME}.tar.gz" "$DOWNLOAD_URL"
    tar -xzf "/tmp/${FRP_FILENAME}.tar.gz" -C /tmp

    # Install binaries
    sudo install "/tmp/${FRP_FILENAME}/frps" "${FRP_INSTALL_DIR}/frps"
    sudo install "/tmp/${FRP_FILENAME}/frpc" "${FRP_INSTALL_DIR}/frpc"

    # Cleanup
    rm -rf "/tmp/${FRP_FILENAME}" "/tmp/${FRP_FILENAME}.tar.gz"

    print_message "FRP v${FRP_VERSION} installed successfully!"
}

# Function to show the main menu
show_menu() {
    while true; do
        echo "====================================="
        echo "  FRP Installer and Management"
        echo "====================================="
        echo "1. Install/Update FRP"
        echo "2. Configure Server (frps)"
        echo "3. Configure Client (frpc)"
        echo "4. Manage Services"
        echo "5. Exit"
        echo "-------------------------------------"
        read -p "Enter your choice [1-5]: " choice

        case $choice in
            1) install_update_frp ;;
            2) configure_server ;;
            3) configure_client ;;
            4) echo "Not yet implemented." ;;
            5) exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

# --- Script Entry Point ---
show_menu
