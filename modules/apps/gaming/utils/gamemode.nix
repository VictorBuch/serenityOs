{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.gaming.gamemode.enable = lib.mkEnableOption "Enables GameMode";
  };

  config = lib.mkIf config.apps.gaming.gamemode.enable {

    environment.systemPackages = with pkgs; [
      gamemode
    ];
  };
}
