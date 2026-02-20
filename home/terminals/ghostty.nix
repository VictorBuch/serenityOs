args@{
  config,
  pkgs,
  lib,
  mkHomeModule,
  ...
}:

let
  ghosttySettings = {
    # Colors, fonts, and opacity are managed by Stylix (gruvbox-dark)
    background-blur-radius = 25;
    window-decoration = false;
    confirm-close-surface = false;
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
