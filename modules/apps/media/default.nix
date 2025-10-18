{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./davinci-resolve.nix
    ./handbrake.nix
    ./ffmpeg.nix
  ];

  options = {
    apps.media.enable = lib.mkEnableOption "Enables all media/video editing apps";
  };

  config = lib.mkIf config.apps.media.enable {
    apps.media.davinci-resolve.enable = lib.mkDefault true;
    apps.media.handbrake.enable = lib.mkDefault true;
    apps.media.ffmpeg.enable = lib.mkDefault true;
  };
}
