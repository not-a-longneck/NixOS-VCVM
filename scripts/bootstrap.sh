#!/usr/bin/env bash

# Configuration
REPO_URL="https://github.com/not-a-longneck/NixOS-VCVM.git"
CONFIG_DIR="/etc/nixos"
BACKUP_DIR="/etc/nixos.old"

echo "🚀 Starting NixOS Bootstrap..."

# 1. Backup the installer's generated files
echo "📦 Backing up installer files to $BACKUP_DIR..."
sudo cp -r "$CONFIG_DIR" "$BACKUP_DIR"

# 2. Clear the current config folder for the new clone
sudo rm -rf "$CONFIG_DIR"/*

# 3. Clone your GitHub repo
echo "🔄 Cloning configuration from GitHub..."
sudo git clone "$REPO_URL" "$CONFIG_DIR"

# 4. Restore the VM's specific hardware config
# This ensures drive IDs and bootloader settings match this specific VM
echo "🛠️ Restoring local hardware-configuration.nix..."
sudo cp "$BACKUP_DIR/hardware-configuration.nix" "$CONFIG_DIR/hardware-configuration.nix"

# 5. Fix ownership for the 'admin' user
sudo chown -R admin:users "$CONFIG_DIR"

# 6. Rebuild and Reboot
echo "❄️ Building the new system configuration..."
if sudo nixos-rebuild boot --flake "$CONFIG_DIR#nixos"; then
    echo "✅ Success! Rebooting in 5 seconds..."
    sleep 5
    reboot
else
    echo "❌ Build failed! Check the errors above."
    exit 1
fi
