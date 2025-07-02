# Project Phases

This document outlines the development phases for the interactive FRP installer script.

## Phase 1: Core Structure & FRP Installation
*   Create the main script file with a menu-driven interface.
*   Implement the "Install/Update FRP" function:
    *   Detect the operating system and architecture.
    *   Fetch the latest FRP release from the official GitHub repository.
    *   Download and extract the binaries.
    *   Install `frps` and `frpc` to `/usr/local/bin`.

## Phase 2: Server & Client Configuration
*   Implement the "Configure Server" function to generate `frps.toml`.
*   Implement the "Configure Client" function to generate `frpc.toml`.
*   Ensure existing configurations are backed up before writing new ones.

## Phase 3: Systemd Integration & Service Management
*   Create `systemd` service file templates for `frps` and `frpc`.
*   Implement the "Manage Services" menu for starting, stopping, restarting, and checking the status of the FRP services.

## Phase 4: Final Touches & Polish
*   Add post-setup feedback to display dashboard URLs and status.
*   Enhance script robustness with improved error handling and input validation.
*   Ensure all non-functional requirements from the PRD are met, such as idempotency and security best practices.
