args@{
  config,
  pkgs,
  lib,
  mkHomeModule,
  ...
}:

let
  ghosttySettings = {
    background-opacity = 0.9;
    background-blur-radius = 25;
    window-decoration = false;
    theme = "catppuccin-mocha";
    confirm-close-surface = false;
    font-family = "JetBrainsMono Nerd Font";
    font-size = 14;
    mouse-scroll-multiplier = 1;
  };
in

mkHomeModule {
  _file = toString ./.;
  name = "ghostty";
  description = "Ghostty terminal emulator";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.ghostty = lib.mkIf pkgs.stdenv.isLinux {
        enable = true;
        settings = ghosttySettings;
      };
      xdg.configFile."ghostty/config" = lib.mkIf pkgs.stdenv.isDarwin {
        text = lib.generators.toKeyValue { } ghosttySettings;
      };
    };
} args
