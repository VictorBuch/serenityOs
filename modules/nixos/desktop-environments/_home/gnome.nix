{
  config,
  options,
  pkgs,
  lib,
  ...
}:

{

  options = {
    home.desktop-environments.gnome.enable = lib.mkEnableOption "Enables gnome home manager";
  };

  config = lib.mkIf config.home.desktop-environments.gnome.enable {
    home.packages = with pkgs; [
    ];

  };
}
