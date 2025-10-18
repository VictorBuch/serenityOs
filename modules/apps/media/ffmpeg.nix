{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.media.ffmpeg.enable = lib.mkEnableOption "Enables FFmpeg for video editing";
  };

  config = lib.mkIf config.apps.media.ffmpeg.enable {
    environment.systemPackages = with pkgs; [
      ffmpeg
    ];
  };
}
