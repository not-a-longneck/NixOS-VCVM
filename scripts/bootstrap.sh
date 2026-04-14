#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/not-a-longneck/NixOS-VCVM.git"
CONFIG_DIR="/etc/nixos"
# Automatically detects the user who ran sudo
REAL_USER=${SUDO_USER:-$USER}

echo "🚀 NixOS Post-Install Bootstrap"
echo "==============================="

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Please run as root (use sudo)"
  exit 1
fi

echo "💾 Step 1: Saving hardware-configuration.nix..."
cp "$CONFIG_DIR/hardware-configuration.nix" /tmp/hardware-configuration.nix

echo "📦 Step 2: Removing default NixOS config..."
rm -rf "$CONFIG_DIR"

echo "📥 Steps 3-6: Cloning and prepping config..."
nix-shell -p git --run "$(cat <<EOF
  git clone "$REPO_URL" "$CONFIG_DIR"
  cp /tmp/hardware-configuration.nix "$CONFIG_DIR/hardware-configuration.nix"
  
  cd "$CONFIG_DIR"
  git config --global --add safe.directory "$CONFIG_DIR"
  git add hardware-configuration.nix
EOF
)"

echo "❄️ Step 7: Running NixOS rebuild..."
# We rebuild first while root owns the files to ensure the flake can be read
nixos-rebuild switch --flake "$CONFIG_DIR#nixos"

echo "🔑 Step 8: Handing ownership back to $REAL_USER..."
chown -R "$REAL_USER":users "$CONFIG_DIR"
chmod -R 755 "$CONFIG_DIR"

echo ""
echo "✨ Bootstrap complete!"
echo "   You can now edit files in $CONFIG_DIR without sudo."
