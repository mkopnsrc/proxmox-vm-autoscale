#!/usr/bin/env bash

#Variable - get current script path
ABS_PATH=$(dirname $0)

#Source the functions script
source <(${ABS_PATH}/install.func)

preinstall_check

# Install script for Proxmox VM Autoscale project
# Repository: https://github.com/fabriziosalmi/proxmox-vm-autoscale

# Variables
INSTALL_DIR="/usr/local/bin/vm_autoscale"
REPO_URL="https://github.com/fabriziosalmi/proxmox-vm-autoscale"
SERVICE_FILE="vm_autoscale.service"
CONFIG_FILE="/usr/local/bin/vm_autoscale/config.yaml"
BACKUP_FILE="/usr/local/bin/vm_autoscale/config.yaml.backup"


# Backup existing config.yaml if it exists
if [ -f "$CONFIG_FILE" ]; then
    msg_info "Backing up existing config.yaml to config.yaml.backup..."
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# Install necessary dependencies
msg_info "Installing necessary dependencies..."
apt-get update
apt-get install -y python3 curl bash git python3-paramiko python3-yaml python3-requests python3-cryptography

# Clone the repository
msg_info "Cloning the repository..."
if [ -d "$INSTALL_DIR" ]; then
    msg_info "Removing existing installation directory..."
    rm -rf "$INSTALL_DIR"
fi

git clone "$REPO_URL" "$INSTALL_DIR"

# Install Python dependencies
msg_info "Installing Python dependencies..."
pip3 install -r "$INSTALL_DIR/requirements.txt"

# Set permissions
msg_info "Setting permissions..."
chmod -R 755 "$INSTALL_DIR"

# Create the systemd service file
msg_info "Creating the systemd service file..."
cat <<EOF > /etc/systemd/system/$SERVICE_FILE
[Unit]
Description=Proxmox VM Autoscale Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 $INSTALL_DIR/autoscale.py
WorkingDirectory=$INSTALL_DIR
Restart=always
User=root
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable the service, and ensure it's not started
msg_info "Reloading systemd, enabling the service..."
systemctl daemon-reload
systemctl enable $SERVICE_FILE

# Post-installation instructions
msg_ok "Installation complete. The service is enabled but not started."
msg_info "To start the service, use: sudo systemctl start $SERVICE_FILE"
msg_info "Logs can be monitored using: journalctl -u $SERVICE_FILE -f"

