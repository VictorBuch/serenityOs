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

    services = { 
      xserver.enable = true; # optional
      displayManager.sddm.enable = true;
      displayManager.sddm.wayland.enable = true;
      desktopManager.plasma6.enable = true;
      displayManager.sddm.settings.General.DisplayServer = "wayland";
      displayManager.defaultSession = lib.mkForce "plasma";
    };

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      konsole
      oxygen
    ];
  };
}
