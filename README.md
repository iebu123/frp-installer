# FRP Installer and Management Script

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
-   **Proxy Management:** Easily add and manage proxies for the `frpc` client, with support for single ports and port ranges.
-   **Automatic Proxy Naming:** Automatically generates proxy names based on the ports, simplifying the configuration process.
-   **User-Friendly Interface:** A clear and visually appealing menu-driven interface for easy navigation and operation.

## Requirements

-   `bash`
-   `curl`
-   `sudo` privileges

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

To add a second, third, or additional client service for other servers:

*   Go to **Manage Services** (Option 4 in the main menu) and select **"Create new client service instance"**.

## Menu Options

The script presents a menu with the following options:

1.  **Install/Update FRP:** Installs or updates `frp` to the latest version.
2.  **Configure Server (frps):** Guides you through the process of creating a configuration file for the `frp` server.
3.  **Configure Client (frpc):** Guides you through the process of creating a configuration file for the `frp` client.
4.  **Manage Services:** Provides a submenu to manage the `systemd` services for `frps` and `frpc`.
5.  **Exit:** Exits the script.

## Configuration

-   The configuration files are stored in `/etc/frp/`.
-   The script will back up any existing configuration files before creating new ones.

## Services

-   The script can create `systemd` services for `frps` and `frpc`.
-   You can manage the services (start, stop, restart, status, logs) from the "Manage Services" menu.
