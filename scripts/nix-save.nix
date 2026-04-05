{ ... }:

{
  environment.interactiveShellInit = ''
    nix-save() {
      CONFIG_DIR="/etc/nixos"

      echo "Force-syncing config from GitHub..."
      
      # 1. Fetch the latest updates
      sudo git -C "$CONFIG_DIR" fetch --all
      
      # 2. Force local files to match the remote 'main' branch
      # This wipes any local edits so GitHub is always the boss!
      if sudo git -C "$CONFIG_DIR" reset --hard origin/main; then
        
        echo "Rebuilding NixOS..."
        if sudo nixos-rebuild switch --flake "$CONFIG_DIR"; then
          gen_num=$(readlink /nix/var/nix/profiles/system | cut -d- -f2)
          echo "Successfully updated to Generation $gen_num! 🎉"
        else
          echo "Rebuild failed! ❌ Check the errors above."
        fi

      else
        echo "Sync failed! ❌ Check your network."
      fi
    }
  '';
}
