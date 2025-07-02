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
            2) echo "Not yet implemented." ;;
            3) echo "Not yet implemented." ;;
            4) echo "Not yet implemented." ;;
            5) exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

# --- Script Entry Point ---
show_menu
