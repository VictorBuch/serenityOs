{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.audio.audacity.enable = lib.mkEnableOption "Enables Audacity";
  };

  config = lib.mkIf config.apps.audio.audacity.enable {
    environment.systemPackages = with pkgs; [
      audacity
    ];
  };
}
