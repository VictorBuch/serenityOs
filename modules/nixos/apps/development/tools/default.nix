{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./docker.nix
  ];

  options = {
    apps.development.tools.linux.enable = lib.mkEnableOption "Enables Linux-specific development tools";
  };

  config = lib.mkIf config.apps.development.tools.linux.enable {
    apps.development.tools.docker.enable = lib.mkDefault true;
  };
}
