{ ... }:

let
  # 1. Define your repo URL here!
  repoUrl = "https://github.com/not-a-longneck/NixOS-VCVM.git";
  configDir = "/etc/nixos";
in
{
  # This makes the URL "permanent" by updating the Git remote every time you rebuild
  system.activationScripts.ensureGitRemote = {
    text = ''
      if [ -d "${configDir}/.git" ]; then
        ${# Using the full path to git to ensure it works during activation}
        git -C "${configDir}" remote set-url origin "${repoUrl}"
      fi
    '';
  };

  environment.interactiveShellInit = ''
    nix-save() {
      echo "Force-syncing config from ${repoUrl}..."
      
      # Ensure the remote is correct before fetching
      git -C "${configDir}" remote set-url origin "${repoUrl}"
      
      # Fetch and Reset (no sudo for git!)
      git -C "${configDir}" fetch --all
      
      if git -C "${configDir}" reset --hard origin/main; then
        echo "Rebuilding NixOS..."
        if sudo nixos-rebuild switch --flake "${configDir}"; then
          gen_num=$(readlink /nix/var/nix/profiles/system | cut -d- -f2)
          echo "Successfully updated to Generation $gen_num! 🎉"
        else
          echo "Rebuild failed! ❌"
        fi
      else
        echo "Sync failed! ❌"
      fi
    }
  '';
}
