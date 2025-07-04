#!/bin/bash
# Interactive Shell Script for Automated FRP Server (frps) & Client (frpc) Setup

# --- Global Variables ---
FRP_INSTALL_DIR="/usr/local/bin"
FRP_CONFIG_DIR="/etc/frp"
FRP_VERSION="" # Will be determined dynamically

# --- Helper Functions ---

# Function to print messages
print_message() {
    echo
    echo "=================================================="
    echo "$1"
    echo "=================================================="
    echo
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

# Helper function to create systemd unit files
_create_systemd_unit_file() {
    local service_type=$1
    local client_name=$2 # Only relevant for frpc

    if [ "$service_type" == "frps" ]; then
        sudo bash -c "cat > /etc/systemd/system/frps.service" <<EOL
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=${FRP_INSTALL_DIR}/frps -c ${FRP_CONFIG_DIR}/frps.toml

[Install]
WantedBy=multi-user.target
EOL
        echo "frps.service created."
    elif [ "$service_type" == "frpc" ]; then
        sudo bash -c "cat > /etc/systemd/system/frpc-${client_name}.service" <<EOL
[Unit]
Description=FRP Client for ${client_name}
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=${FRP_INSTALL_DIR}/frpc -c ${FRP_CONFIG_DIR}/frpc-${client_name}.toml

[Install]
WantedBy=multi-user.target
EOL
        echo "frpc-${client_name}.service created."
    fi
}

# Function to configure frps
configure_server() {
    print_message "Configuring FRP Server (frps)"

    # Prompt for configuration details
    read -p "Enter bind port [default: 7000]: " bindPort
    bindPort=${bindPort:-7000}

    read -p "Enable authentication? [y/N]: " enableAuth
    if [[ "$enableAuth" == "y" || "$enableAuth" == "Y" ]]; then
        read -s -p "Enter authentication token (must be the same on client): " authToken
        echo
    else
        authToken=""
    fi

    read -p "Enable dashboard? [y/N]: " enableDashboard
    if [[ "$enableDashboard" == "y" || "$enableDashboard" == "Y" ]]; then
        read -p "Enter dashboard port [default: 7500]: " dashboardPort
        dashboardPort=${dashboardPort:-7500}
        read -p "Enter dashboard user: " dashboardUser
        read -s -p "Enter dashboard password: " dashboardPassword
        echo
    fi

    read -p "Enable KCP transport protocol? [y/N]: " enableKcp
    if [[ "$enableKcp" == "y" || "$enableKcp" == "Y" ]]; then
        enableQuic="n"
    else
        read -p "Enable QUIC transport protocol? [y/N]: " enableQuic
    fi

    # Create config directory if it doesn't exist
    sudo mkdir -p "$FRP_CONFIG_DIR"

    # Backup existing config
    if [ -f "${FRP_CONFIG_DIR}/frps.toml" ]; then
        sudo mv "${FRP_CONFIG_DIR}/frps.toml" "${FRP_CONFIG_DIR}/frps.toml.bak.$(date +%s)"
        echo "Backed up existing frps.toml to frps.toml.bak.$(date +%s)"

    fi
    # Write new config
    sudo bash -c "cat > ${FRP_CONFIG_DIR}/frps.toml" <<EOL
bindPort = $bindPort
EOL

    if [ -n "$authToken" ]; then
        sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frps.toml" <<EOL
auth.token = "$authToken"
EOL
    fi

    if [[ "$enableDashboard" == "y" || "$enableDashboard" == "Y" ]]; then
        sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frps.toml" <<EOL
webServer.addr = "0.0.0.0"
webServer.port = $dashboardPort
webServer.user = "$dashboardUser"
webServer.password = "$dashboardPassword"
EOL
    fi
    
    if [[ "$enableKcp" == "y" || "$enableKcp" == "Y" ]]; then
        sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frps.toml" <<EOL
kcpBindPort = $bindPort
EOL
    fi

    if [[ "$enableQuic" == "y" || "$enableQuic" == "Y" ]]; then
        sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frps.toml" <<EOL
quicBindPort = $bindPort
EOL
    fi

    print_message "frps.toml created successfully!"

    echo "Verifying server configuration..."
    if sudo ${FRP_INSTALL_DIR}/frps verify -c ${FRP_CONFIG_DIR}/frps.toml &> /dev/null; then
        print_message "Server configuration is valid."
        read -p "Do you want to create and start the frps service now? [Y/n]: " create_service
        if [[ "$create_service" != "n" && "$create_service" != "N" ]]; then
            print_message "Creating and starting frps service..."
            _create_systemd_unit_file "frps"
            sudo systemctl daemon-reload
            sudo systemctl enable frps
            sudo systemctl start frps
            print_message "Service frps status:"
            sudo systemctl status frps
        else
            post_setup_feedback "server"
        fi
    else
        print_message "Server configuration is invalid. Please check the settings."
    fi
}

# Function to configure frpc
configure_client() {
    print_message "Configuring FRP Client (frpc)"

    local clientName
    local serverAddr

    while true; do
        read -p "Enter a unique name for this client instance (e.g., myclient_server_ip): " clientName
        if [ -z "$clientName" ]; then
            echo "Client name cannot be empty. Please try again."
            continue
        fi

        if [ -f "${FRP_CONFIG_DIR}/frpc-${clientName}.toml" ]; then
            read -p "Warning: A configuration with the name '${clientName}' already exists. Overwrite? [y/N]: " overwrite_choice
            if [[ "$overwrite_choice" != "y" && "$overwrite_choice" != "Y" ]]; then
                echo "Aborting configuration for '${clientName}'. Please choose a different name."
                return 1
            fi
        fi
        break
    done

    read -p "Enter the server IP for this client instance: " serverAddr
    if [ -z "$serverAddr" ]; then
        echo "Server IP cannot be empty. Aborting."
        return 1
    fi

    print_message "Configuring FRP Client (frpc) for instance: ${clientName}"

    # Prompt for configuration details
    read -p "Enter server port [default: 7000]: " serverPort
    serverPort=${serverPort:-7000}

    read -p "Is authentication enabled on the server? [y/N]: " enableAuth
    if [[ "$enableAuth" == "y" || "$enableAuth" == "Y" ]]; then
        read -s -p "Enter authentication token (must be the same on server): " authToken
        echo
    else
        authToken=""
    fi

    echo "Select transport protocol:"
    echo "  1. tcp (default)"
    echo "  2. kcp"
    echo "  3. quic"
    read -p "Enter your choice [1-3]: " protocol_choice
    case $protocol_choice in
        2) transportProtocol="kcp" ;;
        3) transportProtocol="quic" ;;
        *) transportProtocol="tcp" ;;
    esac

    read -p "Enable Admin UI? [y/N]: " enableAdminUI
    if [[ "$enableAdminUI" == "y" || "$enableAdminUI" == "Y" ]]; then
        read -p "Enter Admin UI port [default: 7501]: " adminUIPort
        adminUIPort=${adminUIPort:-7501}
        read -p "Enter Admin UI user: " adminUIUser
        read -s -p "Enter Admin UI password: " adminUIPassword
        echo
    fi

    # Create config directory if it doesn't exist
    sudo mkdir -p "$FRP_CONFIG_DIR"

    # Backup existing config
    if [ -f "${FRP_CONFIG_DIR}/frpc-${clientName}.toml" ]; then
        sudo mv "${FRP_CONFIG_DIR}/frpc-${clientName}.toml" "${FRP_CONFIG_DIR}/frpc-${clientName}.toml.bak.$(date +%s)"
        echo "Backed up existing frpc-${clientName}.toml to frpc-${clientName}.toml.bak.$(date +%s)"
    fi

    # Write new config
    sudo bash -c "cat > ${FRP_CONFIG_DIR}/frpc-${clientName}.toml" <<EOL
serverAddr = "${serverAddr}"
serverPort = $serverPort
transport.protocol = "$transportProtocol"
EOL

    if [ -n "$authToken" ]; then
        sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frpc-${clientName}.toml" <<EOL
auth.token = "$authToken"
EOL
    fi

    if [[ "$enableAdminUI" == "y" || "$enableAdminUI" == "Y" ]]; then
        sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frpc-${clientName}.toml" <<EOL
webServer.addr = "0.0.0.0"
webServer.port = $adminUIPort
webServer.user = "$adminUIUser"
webServer.password = "$adminUIPassword"
EOL
    fi

    while true; do
        print_message "Define a proxy"
        read -p "Add a new proxy? [Y/n]: " add_proxy
        if [[ "$add_proxy" == "n" || "$add_proxy" == "N" ]]; then
            break
        fi

        read -p "Proxy type (tcp, udp, http, https) [default: tcp]: " proxyType
        proxyType=${proxyType:-tcp}
        read -p "Local IP [default: 127.0.0.1]: " localIP
        localIP=${localIP:-127.0.0.1}

        read -p "Configure a port range? [y/N]: " is_range
        if [[ "$is_range" == "y" || "$is_range" == "Y" ]]; then
            read -p "Local port range (e.g., 6000-6010): " localPort
            read -p "Remote port range (e.g., 7000-7010): " remotePort

            sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frpc-${clientName}.toml" <<EOL

{{- range \$_, \$v := parseNumberRangePair "$localPort" "$remotePort" }}
[[proxies]]
name = "$proxyType-{{ \$v.First }}"
type = "$proxyType"
localIP = "$localIP"
localPort = {{ \$v.First }}
remotePort = {{ \$v.Second }}
loadBalancer.group = "group-$clientName-{{ \$v.First }}"
loadBalancer.groupKey = "group-$clientName-{{ \$v.First }}"
healthCheck.type = "tcp"
healthCheck.timeoutSeconds = 3
healthCheck.maxFailed = 3
healthCheck.intervalSeconds = 10
{{- end }}
EOL
        else
            read -p "Local port: " localPort
            read -p "Remote port: " remotePort
            proxyName="proxy-${localPort}-${remotePort}"

            sudo bash -c "cat >> ${FRP_CONFIG_DIR}/frpc-${clientName}.toml" <<EOL

[[proxies]]
name = "$proxyName"
type = "$proxyType"
localIP = "$localIP"
localPort = $localPort
remotePort = $remotePort
loadBalancer.group = "group-$clientName-$localPort"
loadBalancer.groupKey = "group-$clientName-$localPort"
healthCheck.type = "tcp"
healthCheck.timeoutSeconds = 3
healthCheck.maxFailed = 3
healthCheck.intervalSeconds = 10
EOL
        fi
    done

    print_message "frpc-${clientName}.toml created successfully!"

    read -p "Do you want to create and start the frpc-${clientName} service now? [Y/n]: " create_service
    if [[ "$create_service" != "n" && "$create_service" != "N" ]]; then
        echo "Verifying client configuration for ${clientName}..."
        if sudo ${FRP_INSTALL_DIR}/frpc verify -c ${FRP_CONFIG_DIR}/frpc-${clientName}.toml &> /dev/null; then
            print_message "Client configuration is valid."
            print_message "Creating and starting frpc-${clientName} service..."
            
            _create_systemd_unit_file "frpc" "${clientName}"
            
            sudo systemctl daemon-reload
            sudo systemctl enable "frpc-${clientName}"
            sudo systemctl start "frpc-${clientName}"
            print_message "Service frpc-${clientName} status:"
            sudo systemctl status "frpc-${clientName}"
        else
            print_message "Client configuration is invalid for ${clientName}. Please check the settings."
        fi
    else
        post_setup_feedback "client"
    fi
}

# Function to manage services
manage_services() {
    while true; do
        echo
        echo "====================================="
        echo "        Service Management"
        echo "====================================="
        echo "1. Create systemd services"
        echo "2. Start a service"
        echo "3. Stop a service"
        echo "4. Restart a service"
        echo "5. Check service status"
        echo "6. View service logs"
        echo "7. Back to main menu"
        echo "-------------------------------------"
        read -p "Enter your choice [1-7]: " service_choice

        case $service_choice in
            1) create_systemd_services ;;
            2) manage_service "start" ;;
            3) manage_service "stop" ;;
            4) manage_service "restart" ;;
            5) manage_service "status" ;;
            6) manage_service "logs" ;;
            7) break ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

create_systemd_services() {
    print_message "Creating systemd service"

    while true; do
        read -p "Which service do you want to create? (server/client): " service_to_create
        case "$service_to_create" in
            server)
                _create_systemd_unit_file "frps"
                break
                ;;
            client)
                configure_client
                break
                ;;
            *)
                echo "Invalid input. Please enter 'server' or 'client'."
                ;;
        esac
    done

    sudo systemctl daemon-reload
    print_message "Systemd service creation process finished."
    echo "You can now enable and start the service."
}

manage_service() {
    action=$1
    read -p "Enter service type (frps/frpc): " service_type

    if [ "$service_type" == "frps" ]; then
        service_name="frps"
    elif [ "$service_type" == "frpc" ]; then
        echo "Available frpc services:"
        mapfile -t frpc_services < <(sudo systemctl list-units --type=service --all | grep -oP 'frpc-\K[^.]+' | sort -u)
        if [ ${#frpc_services[@]} -eq 0 ]; then
            echo "No frpc services found."
            return
        fi

        select service_instance in "${frpc_services[@]}"; do
            if [ -n "$service_instance" ]; then
                service_name="frpc-${service_instance}"
                break
            else
                echo "Invalid selection. Please try again."
            fi
        done
    else
        echo "Invalid service type."
        return
    fi

    case $action in
        start) sudo systemctl start $service_name ;;
        stop) sudo systemctl stop $service_name ;;
        restart) sudo systemctl restart $service_name ;;
        status) sudo systemctl status $service_name ;;
        logs) sudo journalctl -u $service_name -f ;;
    esac
}


# Function to set up automatic service reset
setup_auto_reset() {
    print_message "Setting up Automatic Service Reset"

    read -p "Set up auto-reset for server or client? (server/client): " reset_choice
    if [[ "$reset_choice" != "server" && "$reset_choice" != "client" ]]; then
        echo "Invalid choice. Aborting."
        return
    fi

    # 1. Generate the reset script
    local reset_script_path="/etc/frp/reset_frp_services.sh"
    print_message "Generating reset script for $reset_choice at $reset_script_path"

    if [ "$reset_choice" == "server" ]; then
        sudo bash -c "cat > $reset_script_path" <<'EOL'
#!/bin/bash
echo "Killing any running frps processes to ensure a clean restart..."
pkill -f frps

echo "Reloading systemd manager configuration..."
systemctl daemon-reload

echo "Restarting frps service..."
systemctl restart frps

echo "frps service reset successfully."

# This next command will permanently delete older log entries to reduce the journal size to 1MB.
# This is useful for managing disk space, but be aware that it erases historical log data.
echo "Reducing journal log size to 500MB..."
journalctl --vacuum-size=500M
EOL
    else # client
        sudo bash -c "cat > $reset_script_path" <<'EOL'
#!/bin/bash
echo "Killing any running frpc processes to ensure a clean restart..."
pkill -f frpc

echo "Reloading systemd manager configuration..."
systemctl daemon-reload

echo "Restarting all frpc services..."
for service in $(systemctl list-units --type=service --all 'frpc-*.service' --no-legend | awk '{print $1}'); do
    echo "Restarting $service"
    systemctl restart "$service"
done
echo "FRP client services reset successfully."

# This next command will permanently delete older log entries to reduce the journal size to 1MB.
# This is useful for managing disk space, but be aware that it erases historical log data.
echo "Reducing journal log size to 500MB..."
journalctl --vacuum-size=500M
EOL
    fi

    sudo chmod +x "$reset_script_path"
    print_message "Reset script created and made executable."

    # 2. Set up cron job
    print_message "Setting up cron job for automatic reset"

    echo "Choose the reset frequency:"
    echo "  1. Every 5 minutes"
    echo "  2. Every 10 minutes"
    echo "  3. Every 20 minutes"
    echo "  4. Every 30 minutes"
    echo "  5. Hourly"
    read -p "Enter your choice [1-5, default: 3]: " freq_choice
    freq_choice=${freq_choice:-3}

    local cron_schedule
    case $freq_choice in
        1) cron_schedule="*/5 * * * *" ;;
        2) cron_schedule="*/10 * * * *" ;;
        3) cron_schedule="*/20 * * * *" ;;
        4) cron_schedule="*/30 * * * *" ;;
        5) cron_schedule="0 * * * *" ;;
        *)
            echo "Invalid choice. Defaulting to Daily."
            cron_schedule="0 0 * * *"
            ;;
    esac

    # Remove previous cron job created by this script to avoid duplicates
    (crontab -l 2>/dev/null | grep -v "# frp-installer auto-reset") | crontab -

    # Add new cron job
    (crontab -l 2>/dev/null; echo "$cron_schedule $reset_script_path # frp-installer auto-reset") | crontab -

    print_message "Cron job for automatic reset has been set up."
    echo "Current cron jobs:"
    crontab -l
}

# Function to provide post-setup feedback
post_setup_feedback() {
    type=$1

    if [ "$type" == "server" ]; then
        if [[ "$enableDashboard" == "y" || "$enableDashboard" == "Y" ]]; then
            echo "Dashboard URL: http://<server_ip>:$dashboardPort"
        fi
        echo "frps service is configured. You can start it from the 'Manage Services' menu."
    elif [ "$type" == "client" ]; then
        echo "frpc service is configured. You can start it from the 'Manage Services' menu."
        echo "To test connectivity, you can use: curl -v telnet://<server_ip>:$remotePort"
    fi
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
    if ! curl -L -o "/tmp/${FRP_FILENAME}.tar.gz" "$DOWNLOAD_URL"; then
        echo "Error: Failed to download FRP."
        exit 1
    fi
    
    if ! tar -xzf "/tmp/${FRP_FILENAME}.tar.gz" -C /tmp; then
        echo "Error: Failed to extract FRP."
        exit 1
    fi

    # Install binaries
    if ! sudo install "/tmp/${FRP_FILENAME}/frps" "${FRP_INSTALL_DIR}/frps"; then
        echo "Error: Failed to install frps."
        exit 1
    fi
    
    if ! sudo install "/tmp/${FRP_FILENAME}/frpc" "${FRP_INSTALL_DIR}/frpc"; then
        echo "Error: Failed to install frpc."
        exit 1
    fi

    # Cleanup
    rm -rf "/tmp/${FRP_FILENAME}" "/tmp/${FRP_FILENAME}.tar.gz"

    print_message "FRP v${FRP_VERSION} installed successfully!"
}

# Function to show the main menu
show_menu() {
    local is_first_run=true
    while true; do
        if [ "$is_first_run" = true ]; then
            is_first_run=false
        else
            echo
            read -p "Return to the main menu? The screen will be cleared. (Y/n): " return_to_menu
            if [[ "$return_to_menu" == "n" || "$return_to_menu" == "N" ]]; then
                exit 0
            fi
        fi

        clear
        echo
        echo '
╔══════════════════════════════════════════════════════╗
║                                                      ║
║          ███████ ██████  ██████                      ║
║          ██      ██   ██ ██   ██                     ║
║          █████   ██████  ██████                      ║
║          ██      ██   ██ ██                          ║
║          ██      ██   ██ ██                          ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║          FRP Installer and Management                ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║   1. Install/Update FRP                              ║
║   2. Configure Server (frps)                         ║
║   3. Configure Client (frpc)                         ║
║   4. Manage Services                                 ║
║   5. Set up automatic service reset                  ║
║   6. Exit                                            ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
        '
        read -p "   Enter your choice [1-6]: " choice

        case $choice in
            1) install_update_frp ;;
            2) configure_server ;;
            3) configure_client ;;
            4) manage_services ;;
            5) setup_auto_reset ;;
            6) exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

# --- Script Entry Point ---
show_menu