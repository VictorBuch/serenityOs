{
  config,
  options,
  pkgs,
  lib,
  ...
}:

let
  ghosttySettings = {
    background-opacity = 0.8;
    background-blur-radius = 20;
    window-decoration = false;
    theme = "Catppuccin Mocha";
    confirm-close-surface = false;
  };
in
{
  options = {
    home.terminals.ghostty.enable = lib.mkEnableOption "Enables ghostty home manager";
  };

  config = lib.mkIf config.home.terminals.ghostty.enable {
    programs.ghostty = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      settings = ghosttySettings;
    };
    xdg.configFile."ghostty/config" = lib.mkIf pkgs.stdenv.isDarwin {
      text = lib.generators.toKeyValue { } ghosttySettings;
    };
  };
}
