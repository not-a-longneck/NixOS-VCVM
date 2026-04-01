{ ... }:

{

###############################################
### GIT AUTO COMMIT (Home Manager Link Edition)
###############################################


environment.interactiveShellInit = ''
  if alias nix-save >/dev/null 2>&1; then unalias nix-save; fi

  nix-save() {
    # This points to the folder created by your home.file config
    CONFIG_DIR="$HOME/NixOS"

    echo -n "Enter commit message (or press Enter for 'Auto-backup'): "
    read -r user_msg

    # Stage changes in your NixOS folder
    git -C "$CONFIG_DIR" add .

    # Run the rebuild using the flake in that folder
    if sudo nixos-rebuild switch --flake "$CONFIG_DIR"; then

      gen_num=$(readlink /nix/var/nix/profiles/system | cut -d- -f2)

      if [ -z "$user_msg" ]; then
        final_msg="Gen $gen_num: Auto-backup $(date +'%d-%m-%Y')"
      else
        final_msg="Gen $gen_num: $user_msg"
      fi

      # Commit and push from that same folder
      git -C "$CONFIG_DIR" commit -m "$final_msg"
      git -C "$CONFIG_DIR" push origin main
      echo "Successfully pushed Generation $gen_num to GitHub!"
    else
      echo "Rebuild failed, nothing committed to Git."
    fi
  }
'';

}
