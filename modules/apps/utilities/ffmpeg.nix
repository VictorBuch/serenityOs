{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.utilities.ffmpeg.enable = lib.mkEnableOption "Enables FFmpeg";
  };

  config = lib.mkIf config.apps.utilities.ffmpeg.enable {
    environment.systemPackages = with pkgs; [
      ffmpeg
    ];
  };
}
