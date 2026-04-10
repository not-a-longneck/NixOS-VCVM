{ inputs, config, lib, pkgs, ... }: {

  imports = [
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      inputs.plasma-manager.homeModules.plasma-manager


  ];

  home.username = "admin";
  home.homeDirectory = "/home/admin";
  home.stateVersion = "25.11"; # Use the version you installed

  ###################################
  #### OPEN FILES IN mimeApps    ####
  ###################################

  xdg.enable = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "video/mp4" = [ "vlc.desktop" ];
      "video/x-matroska" = [ "vlc.desktop" ];
      "video/webm" = [ "vlc.desktop" ];
      "video/quicktime" = [ "vlc.desktop" ];
      "video/x-msvideo" = [ "vlc.desktop" ]; # AVI
      "video/mpeg" = [ "vlc.desktop" ];
      "video/ogg" = [ "vlc.desktop" ];
      "video/x-flv" = [ "vlc.desktop" ];       # This covers Flash video
      "video/3gpp" = [ "vlc.desktop" ];        # This covers old phone videos
    };
  };

  ###################################
  #### APPS TO INSTAL WITH HM    
  ###################################

  programs.home-manager.enable = true;
  programs.git.enable = true;


  # Packages just for your user
  home.packages = with pkgs; [
    vlc
    tor-browser
    peazip

  ];

  # Flatpaks
  services.flatpak = {
    enable = true;
    packages = [
      "org.jdownloader.JDownloader"
    ];
  };



  ###################################
  #### PROGRAM SPECIFIC SETTINGS ####
  ###################################

  # VLC Config
  home.file.".config/vlc/vlcrc" = {
    text = ''
      [core]
      metadata-network-access=0
      show-hiddenfiles=1
      playlist-tree=0
      recursive=expand
      random=1
      loop=1
      [qt]
      qt-privacy-ask=0
      qt-notification=0
      qt-video-autoresize=0

  '';
  force = true;

  };


  # Tor browser
  home.file.".tor-project/TorBrowser/Data/Browser/profile.default/user.js" = {
    text = ''
      user_pref("javascript.enabled", false);
      user_pref("extensions.torlauncher.prompt_at_startup", false);
      user_pref("network.bootstrapped", true);
      user_pref("intl.accept_languages", "en-US, en");
      user_pref("intl.locale.requested", "en-US");
      user_pref("browser.toolbars.bookmarks.visibility", "never");
    '';
  };



  # JDownloader Permissions (Separated for clarity)
services.flatpak.overrides."org.jdownloader.JDownloader".Context = {
    filesystems = [
      "xdg-download:rw"
      "/tmp:rw"
      "/mnt:rw"
      "/mnt/veracrypt1/:rw"
    ];
    # ADD THESE TWO LINES:
    sockets = [ "x11" "wayland" "fallback-x11" ];
    shared = [ "network" "ipc" ];
    bus-talk = [ "org.freedesktop.NetworkManager" ];
  };


  # ====================================
  # PLASMA KDE SPECIFIC
  # ====================================
  
  programs.plasma = {
    enable = true;
    configFile."ksmserverrc"."General"."loginMode" = "emptySession";
  };

  ####################################
  #### Symlinks                   ####
  ####################################

  home.file."Unraid".source = config.lib.file.mkOutOfStoreSymlink "/mnt/tower/backups";




  #-----------

}
