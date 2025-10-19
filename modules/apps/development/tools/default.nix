{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./common.nix
    ./docker.nix
  ];

  options = {
    apps.development.tools.enable = lib.mkEnableOption "Enables all development tools";
  };

  config = lib.mkIf config.apps.development.tools.enable {
    apps.development.tools.common.enable = lib.mkDefault true;
  };
}
