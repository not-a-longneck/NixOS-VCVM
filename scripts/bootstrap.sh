#!/usr/bin/env bash
set -e  # Exit on any error
 
REPO_URL="https://github.com/not-a-longneck/NixOS-VCVM.git"
CONFIG_DIR="/etc/nixos"
 
echo "🚀 NixOS Bootstrap Script"
echo "========================="
echo ""
 
# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Please run as root (use sudo)"
  exit 1
fi
 
echo "📦 Step 1: Removing default NixOS config..."
rm -rf "$CONFIG_DIR"
 
echo "📥 Step 2: Cloning configuration from GitHub..."
git clone "$REPO_URL" "$CONFIG_DIR"
 
echo "🔑 Step 3: Setting permissions..."
chown -R admin:users "$CONFIG_DIR"
chmod -R 755 "$CONFIG_DIR"
 
echo "❄️  Step 4: Running first NixOS rebuild..."
echo "   (This may take a while...)"
nixos-rebuild switch --flake "$CONFIG_DIR#nixos"
 
echo ""
echo "✨ Bootstrap complete!"
echo "   You can now use 'nix-save' to pull updates from GitHub."
