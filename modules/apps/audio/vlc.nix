{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.audio.vlc.enable = lib.mkEnableOption "Enables VLC media player";
  };

  config = lib.mkIf config.apps.audio.vlc.enable {
    environment.systemPackages = with pkgs; [
      vlc
    ];
  };
}
