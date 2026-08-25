{
  config,
  options,
  pkgs,
  lib,
  ...
}:

{

  options = {
    home.desktop.environment.gnome.enable = lib.mkEnableOption "Enables gnome home manager";
  };

  config = lib.mkIf config.home.desktop.environment.gnome.enable {
    home.packages = with pkgs; [
    ];

  };
}
