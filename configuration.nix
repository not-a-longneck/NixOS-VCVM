# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./scripts/nix-save.nix
    ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  #######################
  ### HARDWARE        ###
  #######################



  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;






  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.admin = {
    isNormalUser = true;
    description = "admin";
    extraGroups = [ "networkmanager" "wheel" ];
    hashedPassword = "$6$Osqk1/PTMVPFxz.R$xnhXNz5ePRgPQZtGMaXlSDInDsrwNocuRqVmTfZcq4ujAer6PiesG27vZpkxdMJh3gtSzP9qOlTs8CTP9Pf.f/";

  };



  # ==============================
  # ==== Apps and tools       ====
  # ==============================

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  services.flatpak.enable = true;


  environment.systemPackages = with pkgs; [
    spice-vdagent # for vm features
    veracrypt
    kdePackages.kate
    cifs-utils

  ];


  # ==============================
  # ==== VM Specific          ====
  # ==============================


  # This handles the system-level daemon
  services.spice-vdagentd.enable = true;

    # ================================
    # ==== Mounts and filesystem  ====
    # ================================


    fileSystems."/mnt/tower/backups" = {
      device = "//192.168.1.53/backups";
      fsType = "cifs";
      # Force read-write and give you (uid=1000) full control
      options = [
        "guest,uid=1000,gid=100,rw,iocharset=utf8,file_mode=0777,dir_mode=0777,noperm,_netdev"
        "x-systemd.automount,x-systemd.idle-timeout=60"
      ];
    };

  #grant admin sudo rights to vc drives
  services.udev.extraRules = ''
    KERNEL=="dm-*", ENV{ID_FS_USAGE}=="filesystem", OWNER="admin", GROUP="users", MODE="0775"
  '';

  # Ensure ownership over nix folder:
  system.activationScripts.nixosFolderPermissions = {
    text = ''
      chown -R admin:users /etc/nixos
      chmod -R 755 /etc/nixos
    '';
  };



  # ===============================
  # ==== User settings         ====
  # ===============================

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";

  # Configure keymap in X11
  console.keyMap = "dk";
  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };

    environment.shellAliases = {
      copypaste = "spice-vdagent";
  };


  ## Testing github build


  ######
  system.stateVersion = "25.11"; # Did you read the comment?

}
