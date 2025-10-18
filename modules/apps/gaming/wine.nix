{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.gaming.wine.enable = lib.mkEnableOption "Enables Wine";
  };

  config = lib.mkIf config.apps.gaming.wine.enable {

    environment.systemPackages = with pkgs; [
      # Steam configurations
      wineWowPackages.stable
      wineWowPackages.waylandFull
      winetricks
      protontricks
    ];
  };
}
