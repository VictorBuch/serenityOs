{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.gaming.heroic.enable = lib.mkEnableOption "Enables Heroic Games Launcher";
  };

  config = lib.mkIf config.apps.gaming.heroic.enable {

    environment.systemPackages = with pkgs; [
      heroic
    ];
  };
}
