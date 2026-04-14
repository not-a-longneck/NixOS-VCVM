#!/usr/bin/env bash
set -e  # Exit on any error

REPO_URL="https://github.com/not-a-longneck/NixOS-VCVM.git"
CONFIG_DIR="/etc/nixos"

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Please run as root (use sudo)"
  exit 1
fi

echo "💾 Step 1: Saving hardware-configuration.nix..."
cp "$CONFIG_DIR/hardware-configuration.nix" /tmp/hardware-configuration.nix

echo "📦 Step 2: Removing default NixOS config..."
rm -rf "$CONFIG_DIR"

echo "📥 Steps 3: Cloning and prepping config..."
nix-shell -p git --run "$(cat <<EOF
  git clone "$REPO_URL" "$CONFIG_DIR"
  cp /tmp/hardware-configuration.nix "$CONFIG_DIR/hardware-configuration.nix"
  
  cd "$CONFIG_DIR"
  # This prevents the 'dubious ownership' error
  git config --global --add safe.directory "$CONFIG_DIR"
  git add hardware-configuration.nix
EOF
)"

echo "🔑 Step 4: Setting permissions..."
# Using root:root for the first run is safer on a fresh install
chown -R root:root "$CONFIG_DIR"
chmod -R 755 "$CONFIG_DIR"

echo "❄️ Step 5: Running first NixOS rebuild..."
nixos-rebuild switch --flake "$CONFIG_DIR#nixos"

echo "✨ Bootstrap complete!"
echo "   You can now use 'nix-save' to pull updates from GitHub."
