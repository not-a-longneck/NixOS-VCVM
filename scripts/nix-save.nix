{ ... }:

let
  # Define your public repository URL here
  repoUrl = "https://github.com/not-a-longneck/NixOS-VCVM.git";
  configDir = "/etc/nixos";
in
{
  environment.interactiveShellInit = ''
    nix-save() {
      echo "Syncing from ${repoUrl}..."

      # Ensure the local folder points to the correct repo URL
      git -C "${configDir}" remote set-url origin "${repoUrl}" 2>/dev/null || \
      git -C "${configDir}" remote add origin "${repoUrl}"

      # Fetch and Reset
      git -C "${configDir}" fetch origin
      
      if git -C "${configDir}" reset --hard origin/main; then
        echo "Rebuilding NixOS..."
        if sudo nixos-rebuild switch --flake "${configDir}"; then
          gen_num=$(readlink /nix/var/nix/profiles/system | cut -d- -f2)
          echo "Success! Now on Generation $gen_num! 🚀"
        else
          echo "Rebuild failed! Check the logs. ❌"
        fi
      else
        echo "Could not sync from GitHub. ❌"
      fi
    }
  '';
}
