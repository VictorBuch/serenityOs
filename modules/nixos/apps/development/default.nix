{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./tools
  ];

  options = {
    apps.development.linux.enable = lib.mkEnableOption "Enables Linux-specific development apps";
  };

  config = lib.mkIf config.apps.development.linux.enable {
    apps.development.tools.linux.enable = lib.mkDefault true;
  };
}
