{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.audio.easyeffects.enable = lib.mkEnableOption "Enables EasyEffects";
  };

  config = lib.mkIf config.apps.audio.easyeffects.enable {
    environment.systemPackages = with pkgs; [
      easyeffects
    ];
  };
}
