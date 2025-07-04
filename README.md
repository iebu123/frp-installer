# FRP Installer and Management Script

[Persian README (راهنمای فارسی)](README_fa.md)

This script provides an interactive and automated way to install, configure, and manage `frp` (a fast reverse proxy) on your system. It simplifies the setup of both the `frp` server (`frps`) and client (`frpc`).

## Quick Start

You can download and run the script with a single command:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/iebu123/frp-installer/main/frp_installer.sh)
```

## Features

-   **Automated Installation/Update:** Downloads and installs the latest version of `frp` for your OS and architecture.
-   **Interactive Configuration:** Guides you through the process of configuring both `frps` and `frpc` with a user-friendly menu.
-   **Configuration Validation:** Verifies the generated configuration files to ensure they are valid.
-   **Systemd Service Management:** Creates and manages `systemd` services for `frps` and `frpc`, allowing you to easily start, stop, restart, and check the status of the services.
-   **Automatic Service Reset:** Set up a cron job to automatically reset `frp` services daily, weekly, or monthly to ensure they are always running smoothly.
-   **Proxy Management:** Easily add and manage proxies for the `frpc` client, with support for single ports and port ranges.
-   **Automatic Proxy Naming:** Automatically generates proxy names based on the ports, simplifying the configuration process.
-   **User-Friendly Interface:** A clear and visually appealing menu-driven interface for easy navigation and operation.

## What this script does:

1.  **Downloads compiled FRP tunnel files:** Saves them to `/usr/local/bin`.
2.  **Creates configuration files for FRP:** These are located in the `/etc/frp` directory.
3.  **Creates systemd services:** Launches the tunnel using the generated configurations. The service files are stored in `/etc/systemd/system/frps.service` for the server and `/etc/systemd/system/frpc-<custom_name>.service` for each client instance.
4.  **Dedicated client service files:** Each client service is created with a unique name, allowing for independent management and configuration for different server connections.
5.  **(Optional) Automatic Service Reset:** Creates a cron job to automatically restart all `frp` services at a specified frequency (daily, weekly, or monthly).

To view the list of created client tunnels, run the following command:
```bash
systemctl list-units --type=service | grep frpc-
```

## How to view logs

To view the last 50 lines of logs for a service:

*   **For server:** `journalctl -u frps.service -n 50`
*   **For client:** `journalctl -u frpc-<client_name>.service -n 50`

## Requirements

-   `bash`
-   `curl`
-   `sudo` privileges
-   `cron` (for the automatic service reset feature)

## Usage

1.  Make the script executable:
    ```bash
    chmod +x frp_installer.sh
    ```
2.  Run the script:
    ```bash
    ./frp_installer.sh
    ```

### Recommended Workflow

To set up your FRP tunnel, follow these steps:

1.  **Install the tunnel** (Option 1 in the main menu).
2.  **Configure the server and client** (Options 2 and 3 in the main menu):
    *   First, configure the server (e.g., located inside Iran, China, etc.), then create and start its service.
    *   Next, configure the client (e.g., on a server outside the country, with no restrictions).
3.  **(Optional) Set up automatic service reset** (Option 5 in the main menu) to ensure the services remain active.

To add a second, third, or additional client service for other servers: 

*   Run again option 3 in main menu: Configure Client (frpc)

## Menu Options

The script presents a menu with the following options:

1.  **Install/Update FRP:** Installs or updates `frp` to the latest version.
2.  **Configure Server (frps):** Guides you through the process of creating a configuration file for the `frp` server.
3.  **Configure Client (frpc):** Guides you through the process of creating a configuration file for the `frp` client.
4.  **Manage Services:** Provides a submenu to manage the `systemd` services for `frps` and `frpc`.
5.  **Set up automatic service reset:** Creates a cron job to automatically restart all `frp` services.
6.  **Exit:** Exits the script.

## Configuration

-   The configuration files are stored in `/etc/frp/`.
-   The script will back up any existing configuration files before creating new ones.

## Services

-   The script can create `systemd` services for `frps` and `frpc`.
-   You can manage the services (start, stop, restart, status, logs) from the "Manage Services" menu.