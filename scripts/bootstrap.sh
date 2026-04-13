#!/usr/bin/env bash

REPO_URL="https://github.com/not-a-longneck/NixOS-VCVM.git"

echo "🚀 Starting UEFI-Aware Bootstrap..."

# 1. Backup original files
sudo cp -r /etc/nixos /etc/nixos.old

# 2. Clear and Clone
sudo rm -rf /etc/nixos/*
sudo git clone "$REPO_URL" /etc/nixos

# 3. FIX BOOTLOADER: Use the VM's native hardware-configuration
# This contains the 'systemd-boot' settings if you installed with UEFI
sudo cp /etc/nixos.old/hardware-configuration.nix /etc/nixos/hardware-configuration.nix

# 4. Permissions for admin
sudo chown -R admin:users /etc/nixos

# 5. Build and Reboot
# We use 'switch' to ensure the bootloader installs correctly now
if sudo nixos-rebuild switch --flake /etc/nixos#nixos; then
    echo "✅ Success! Rebooting..."
    sleep 3
    reboot
else
    echo "❌ Still failing. Manual check required."
fi
