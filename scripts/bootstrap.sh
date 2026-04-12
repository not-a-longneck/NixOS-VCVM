#!/usr/bin/env bash

REPO_URL="https://github.com/not-a-longneck/NixOS-VCVM.git"

echo "🚀 Bootstrapping NixOS to /etc/nixos..."

# 1. Clean out the default installation files
sudo rm -rf /etc/nixos/*

# 2. Clone your repo directly into /etc/nixos
sudo git clone "$REPO_URL" /etc/nixos

# 3. Fix permissions so your 'admin' user owns it (as per your config)
sudo chown -R admin:users /etc/nixos 

# 4. Apply the config using your 'nixos' output name
sudo nixos-rebuild boot --flake /etc/nixos#nixos [cite: 115, 164]

echo "✅ Done! Rebooting in 5 seconds..."
sleep 5
reboot
