{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    desktop.environment.kde.enable = lib.mkEnableOption "the KDE Plasma Desktop Environment";
  };

  config = lib.mkIf config.desktop.environment.kde.enable {
    desktop.loginManager.sddm.enable = true;
    services.xserver.enable = true; # optional
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.settings.General.DisplayServer = "wayland";
    services.displayManager.defaultSession = "plasma";

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      konsole
      oxygen
    ];
  };
}
