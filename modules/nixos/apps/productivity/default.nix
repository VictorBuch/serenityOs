{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./syncthing.nix
  ];

  options = {
    apps.productivity.linux.enable = lib.mkEnableOption "Enables Linux-specific productivity apps";
  };

  config = lib.mkIf config.apps.productivity.linux.enable {
    apps.productivity.syncthing.enable = lib.mkDefault true;
  };
}
