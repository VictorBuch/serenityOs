{
  config,
  pkgs,
  lib,
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
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.settings.General.DisplayServer = "wayland";
    services.displayManager.defaultSession = "plasma";

    environment.plasma6.excludePackages = with pkgs.unstable.kdePackages; [
      plasma-browser-integration
      konsole
      oxygen
    ];
  };
}
