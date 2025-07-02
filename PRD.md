# 🧾 Product Requirements Document (PRD)

## Title  
Interactive Shell Script for Automated FRP Server (frps) & Client (frpc) Setup from the GitHub repository: https://github.com/fatedier/frp

---

## Overview  
An interactive POSIX shell script to install, configure, and manage both FRP components:

- **frps**: the publicly exposed server  
- **frpc**: the client behind NAT/firewall  

The script generates TOML config files, supports token-based authentication, port/range mapping, enables the dashboard, and creates `systemd` services for automated operation.

---

## Problem Statement  
Manual FRP setup is complex and error‑prone:

- Identifying and downloading matching binaries per OS/arch
- Writing two TOML configuration files (`frps.toml`, `frpc.toml`) with correct syntax  based on user input  for server or client
- Matching token and port settings between server and client  
- Setting up `systemd` for both components  
- Ensuring idempotent upgrades and guided input

---

## Objectives  
- **Interactive menu-driven UI**  
- Support **TOML** config  
- Use **token-based authentication** only  
- Support **port range mapping** via `[allowPorts]` and proxy definitions  
- Enable **dashboard UI** on server/client side  
- Generate and maintain `systemd` services for **frps** and **frpc**

---

## Functional Requirements  

### 🎮 Interactive Menu
1. **Install/Update FRP** (detect OS/arch, fetch latest release)  
2. **Configure Server** (`frps.toml`)  
3. **Configure Client** (`frpc.toml`)  
4. **Manage Services** (start/restart/status logs)  
5. **Exit**

### ✅ Installation
- Detect OS (Debian/Ubuntu/CentOS/Fedora/Arch)
- Download latest FRP binaries from GitHub: https://github.com/fatedier/frp/releases/latest
- Install `frps` & `frpc` to `/usr/local/bin/`

### ⚙️ Server Config (`frps.toml`)
**Interactive prompts:**
- `bindPort` (default: `7000`)
- `auth.token` (user input)
- Server dashboard: `webServer.port` (e.g., `7500`) , `webServer.user`, `webServer.password`
- Enable kcp transport protocol 
- Enable quic transport protocol 
- Output to `/etc/frp/frps.toml`, back up existing versions

### ⚙️ Client Config (`frpc.toml`)
**Interactive prompts:**
- `serverAddr`, `serverPort` (default port: `7000`)
- `auth.token`
- `transport.protocol` (`tcp`, `kcp`, `quic`) (default: `tcp`)
- Client Admin UI: `webServer.port` (e.g., `7500`) , `webServer.user`, `webServer.password`
- **Proxy definition:**
  - `type` (`tcp`, `udp`, `http`, `https`)
  - `localIP`, `localPort`, `remotePort` (default local ip: `127.0.0.1`)
  - support port range mapping with the built-in parseNumberRangePair function
- Supports single proxy only
- Output to `/etc/frp/frpc.toml`

### 🔧 Systemd Service Templates
Create:
- `/etc/systemd/system/frps.service`
- `/etc/systemd/system/frpc.service`


Enable and start via:
- `systemctl daemon-reload`
- `systemctl enable frps frpc`
- `systemctl start frps frpc`

---

### 🌐 Post‑Setup Feedback

After setup, display:
- Dashboard URL: `http://<server>:<port>` (If the user has enabled it)
- Confirmation of frpc auto-start
- Optional connectivity test (e.g., `curl`, `nc`)

---

### 🛠️ Non‑Functional Requirements
- Language: POSIX bash
- Idempotent: safe reruns, backups
- Dependencies: curl, tar, systemd, awk, grep, bash
- Cross‑distro compatibility
- Security: hide token inputs, no echo
- Logging: minimal script logs; rely on systemd

---

### 👤 User Stories
1. Server Admin installs FRP server; sees dashboard
2. DevOps Engineer configures client; exposes TCP app
3. Support Staff updates binaries via menu

---

### 📦 Dependencies
- Linux system with systemd
- Required CLI tools available
- Internet access (optional offline switch)
- User provides valid token

---

### 🚫 Limitations
- No multi‑proxy or multiplexing
- No OIDC/TLS authentication
- No TLS for dashboard
- No container or non-systemd support

---

### 🔮 Future Considerations
- Add multi‑proxy support
- Extend auth (OIDC/TLS)
- TLS-secured dashboard
- Dockerized/scripted for containers
- Monitoring and metrics

---

### ✅ Next Steps
- Confirm single proxy design is acceptable
- Confirm port range mapping semantics
- Validate OS release detection and backup strategy

Once approved, proceed to script implementation with interactive menus and templates.

---

