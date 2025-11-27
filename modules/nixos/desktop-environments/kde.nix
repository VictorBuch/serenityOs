{
  config,
  pkgs,
  lib,
  unstable-pkgs,
  ...
}:
{

  imports = [
    ./sddm.nix
  ];

  options = {
    desktop-environments.kde.enable = lib.mkEnableOption "Enables KDE";
  };

  config = lib.mkIf config.desktop-environments.kde.enable {
    sddm.enable = true;
    services.xserver.enable = true; # optional
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.displayManager.sddm.wayland.enable = true;
    services.xserver.desktopManager.plasma6.enable = true;
    services.xserver.displayManager.sddm.settings.General.DisplayServer = "wayland";
    services.xserver.displayManager.defaultSession = "plasma";

    environment.plasma6.excludePackages = with unstable-pkgs.kdePackages; [
      plasma-browser-integration
      konsole
      oxygen
    ];
  };
}
