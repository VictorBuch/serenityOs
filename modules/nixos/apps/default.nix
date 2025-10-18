{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./gaming
    ./emulation
    ./development
    ./productivity
    ./audio
    ./emacs
  ];

  options = {
    apps.linux.enable = lib.mkEnableOption "Enables all Linux-specific apps";
  };

  config = lib.mkIf config.apps.linux.enable {
    apps.gaming.linux.enable = lib.mkDefault true;
    apps.emulation.linux.enable = lib.mkDefault true;
    apps.development.linux.enable = lib.mkDefault true;
    apps.productivity.linux.enable = lib.mkDefault true;
    apps.audio.linux.enable = lib.mkDefault true;
    apps.emacs.linux.enable = lib.mkDefault true;
  };
}
