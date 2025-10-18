{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./reaper.nix
  ];

  options = {
    apps.audio.linux.enable = lib.mkEnableOption "Enables Linux-specific audio apps";
  };

  config = lib.mkIf config.apps.audio.linux.enable {
    apps.audio.reaper.enable = lib.mkDefault true;
  };
}
