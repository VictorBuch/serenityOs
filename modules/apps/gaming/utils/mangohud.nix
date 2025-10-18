{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.gaming.mangohud.enable = lib.mkEnableOption "Enables MangoHud";
  };

  config = lib.mkIf config.apps.gaming.mangohud.enable {

    environment.systemPackages = with pkgs; [
      mangohud
    ];
  };
}
