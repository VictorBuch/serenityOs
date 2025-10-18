{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./podman.nix
    ./virtmanager.nix
    ./virtualbox.nix
  ];

  options = {
    apps.emulation.linux.enable = lib.mkEnableOption "Enables Linux-specific emulation tools";
  };

  config = lib.mkIf config.apps.emulation.linux.enable {
    apps.emulation.podman.enable = lib.mkDefault true;
    apps.emulation.virtmanager.enable = lib.mkDefault true;
    apps.emulation.virtualbox.enable = lib.mkDefault true;
  };
}
