{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.media.handbrake.enable = lib.mkEnableOption "Enables HandBrake";
  };

  config = lib.mkIf config.apps.media.handbrake.enable {
    environment.systemPackages = with pkgs; [
      handbrake
    ];
  };
}
