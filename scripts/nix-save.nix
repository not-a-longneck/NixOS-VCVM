{ ... }:

{
  environment.interactiveShellInit = ''
    nix-save() {
      CONFIG_DIR="/etc/nixos"

      echo "Force-syncing config from GitHub..."
      
      # 1. Fetch as the logged-in user (no sudo needed!)
      git -C "$CONFIG_DIR" fetch --all
      
      # 2. Reset as the logged-in user
      if git -C "$CONFIG_DIR" reset --hard origin/main; then
        
        echo "Rebuilding NixOS..."
        # 3. Only use sudo for the actual system rebuild
        if sudo nixos-rebuild switch --flake "$CONFIG_DIR";
        then
          gen_num=$(readlink /nix/var/nix/profiles/system | cut -d- -f2)
          echo "Successfully updated to Generation $gen_num! 🎉"
        else
          echo "Rebuild failed! ❌ Check the errors above."
        fi

      else
        echo "Sync failed! ❌ Check your network or SSH keys."
      fi
    }
  '';
}
