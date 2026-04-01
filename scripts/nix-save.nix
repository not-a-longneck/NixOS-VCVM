{ ... }:

{

###############################################
### GIT AUTO COMMIT (Home Manager Link Edition)
###############################################


environment.interactiveShellInit = ''
    nix-save() {
      CONFIG_DIR="/etc/nixos"

      echo -n "Enter commit message (or press Enter for 'Auto-backup'): "
      read -r user_msg

      # No sudo needed for git anymore!
      git -C "$CONFIG_DIR" add .

      # Sudo is still needed here because we are changing the OS
      if sudo nixos-rebuild switch --flake "$CONFIG_DIR"; then

        gen_num=$(readlink /nix/var/nix/profiles/system | cut -d- -f2)

        if [ -z "$user_msg" ]; then
          final_msg="Gen $gen_num: Auto-backup $(date +'%d-%m-%Y')"
        else
          final_msg="Gen $gen_num: $user_msg"
        fi

        git -C "$CONFIG_DIR" commit -m "$final_msg"
        git -C "$CONFIG_DIR" push origin main
        echo "Successfully pushed Generation $gen_num to GitHub!"
      else
        echo "Rebuild failed, nothing committed."
      fi
    }
  '';

}
