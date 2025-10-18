{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./editors
    ./terminals
    ./tools
  ];

  options = {
    apps.development.enable = lib.mkEnableOption "Enables all development apps";
  };

  config = lib.mkIf config.apps.development.enable {
    apps.development.editors.enable = lib.mkDefault true;
    apps.development.terminals.enable = lib.mkDefault true;
    apps.development.tools.enable = lib.mkDefault true;
  };
}
