{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./audacity.nix
    ./easyeffects.nix
    ./spotify.nix
    ./vlc.nix
  ];

  options = {
    apps.audio.enable = lib.mkEnableOption "Enables all audio apps";
  };

  config = lib.mkIf config.apps.audio.enable {
    apps.audio.audacity.enable = lib.mkDefault true;
    apps.audio.easyeffects.enable = lib.mkDefault true;
    apps.audio.spotify.enable = lib.mkDefault true;
    apps.audio.vlc.enable = lib.mkDefault true;
  };
}
