{ ... }:

let
  # Change this to your actual repository URL
  repoUrl = "https://github.com/not-a-longneck/NixOS-VCVM.git";
  configDir = "/etc/nixos";
  backupDir = "/etc/nixos.bak";
in
{
  environment.interactiveShellInit = ''
    nix-save() {
      echo "📦 Step 1: Creating backup at ${backupDir}..."
      # Remove old backup and create a fresh one
      sudo rm -rf "${backupDir}"
      sudo cp -r "${configDir}" "${backupDir}"
      sudo chown -R admin:users "${backupDir}"

      echo "🔄 Step 2: Syncing from GitHub..."
      # Ensure the remote URL is always correct
      git -C "${configDir}" remote set-url origin "${repoUrl}" 2>/dev/null || \
      git -C "${configDir}" remote add origin "${repoUrl}"

      git -C "${configDir}" fetch origin
      
      if git -C "${configDir}" reset --hard origin/main; then
        echo "❄️ Step 3: Rebuilding NixOS..."
        if sudo nixos-rebuild switch --flake "${configDir}#nixos"; then
          gen_num=$(readlink /nix/var/nix/profiles/system | cut -d- -f2)
          echo "✨ Success! Backup saved and updated to Generation $gen_num!"
        else
          echo "❌ Rebuild failed! You can find your previous files in ${backupDir}"
        fi
      else
        echo "❌ Sync failed! Check your internet connection."
      fi
    }
  '';
}
