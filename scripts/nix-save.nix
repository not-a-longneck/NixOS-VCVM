{ ... }:

let
  repoUrl = "https://github.com/not-a-longneck/NixOS-VCVM.git";
  configDir = "/etc/nixos";
  backupDir = "/etc/nixos.bak";
in
{
  environment.interactiveShellInit = ''
    # --- The Save & Sync Command ---
    nix-save() {
      echo "📦 Step 1: Creating backup at ${backupDir}..."
      sudo rm -rf "${backupDir}"
      sudo cp -r "${configDir}" "${backupDir}"
      sudo chown -R admin:users "${backupDir}"

      echo "🔄 Step 2: Syncing from GitHub..."
      # Ensure remote is correct
      git -C "${configDir}" remote set-url origin "${repoUrl}" 2>/dev/null || \
      git -C "${configDir}" remote add origin "${repoUrl}"

      git -C "${configDir}" fetch origin
      
      # Hard reset to match GitHub + Clean up any local junk
      if git -C "${configDir}" fetch origin && git -C "${configDir}" reset --hard origin/main; then
        echo "❄️ Step 3: Rebuilding NixOS..."
        if sudo nixos-rebuild switch --flake "${configDir}#nixos"; then
          gen_num=$(readlink /nix/var/nix/profiles/system | cut -d- -f2)
          echo "✨ Success! Updated to Generation $gen_num!"
        else
          echo "❌ Rebuild failed! Your old files are safe in ${backupDir}"
          echo "💡 Run 'nix-restore' to get back to the working version"
        fi
      else
        echo "❌ Sync failed! Check your connection to GitHub."
      fi
    }
  '';
}
