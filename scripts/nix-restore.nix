{ ... }:

let
  configDir = "/etc/nixos";
  backupDir = "/etc/nixos.bak";
in
{
  environment.interactiveShellInit = ''
    nix-restore() {
      if [ ! -d "${backupDir}" ]; then
        echo "❌ Error: No backup found at ${backupDir}!"
        return 1
      fi

      echo "🛠️ Restoring system from ${backupDir}..."

      # 1. Swap the folders
      sudo rm -rf "${configDir}"
      sudo cp -r "${backupDir}" "${configDir}"

      # 2. Fix permissions for the admin user
      sudo chown -R admin:users "${configDir}"
      echo "✅ Success! You've been restored to your previous state and you can now run manual nixos-rebuild switch command. ✨"
    
    }
  '';
}
