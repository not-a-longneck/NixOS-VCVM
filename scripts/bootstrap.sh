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

echo "💾 Step 1: Saving hardware-configuration.nix..."
cp "$CONFIG_DIR/hardware-configuration.nix" /tmp/hardware-configuration.nix

echo "📦 Step 2: Removing default NixOS config..."
rm -rf "$CONFIG_DIR"

echo "📥 Step 3: Cloning configuration from GitHub..."
nix-shell -p git --run '
  git clone $REPO_URL $CONFIG_DIR
  
  echo "🔧 Step 4: Restoring hardware-configuration.nix..."
  cp /tmp/hardware-configuration.nix "$CONFIG_DIR/hardware-configuration.nix"
  
  echo "🔑 Step 5: Setting permissions..."
  chown -R admin:users "$CONFIG_DIR"
  chmod -R 755 "$CONFIG_DIR"
  
  echo "📝 Step 6: Adding hardware-configuration.nix to git..."
  cd "$CONFIG_DIR"
  git add hardware-configuration.nix'

echo "❄️  Step 7: Running first NixOS rebuild..."
echo "   (This may take a while...)"
nixos-rebuild switch --flake "$CONFIG_DIR#nixos"

echo ""
echo "✨ Bootstrap complete!"
echo "   You can now use 'nix-save' to pull updates from GitHub."
