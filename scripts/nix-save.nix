{ ... }:

{
  environment.interactiveShellInit = ''
    nix-save() {
      CONFIG_DIR="/etc/nixos"

      echo "Fetching latest config from GitHub..."
      # Pulling via HTTPS completely bypasses the need for SSH keys/logins
      if git -C "$CONFIG_DIR" pull https://github.com/not-a-longneck/NixOS-VCVM main; then

        echo "Rebuilding NixOS..."
        if sudo nixos-rebuild switch --flake "$CONFIG_DIR"; then
          gen_num=$(readlink /nix/var/nix/profiles/system | cut -d- -f2)
          echo "Successfully updated and rebuilt to Generation $gen_num! 🎉"
        else
          echo "Rebuild failed! ❌ Check the errors above."
        fi

      else
        echo "Git pull failed! ❌ Check your network or repo URL."
      fi
    }
  '';
}
