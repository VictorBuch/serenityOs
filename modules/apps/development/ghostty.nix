args@{ config, pkgs, lib, mkModule, ... }:

let
  ghosttySettings = {
    # Colors come from noctalia's `ghostty` template: it writes
    # ~/.config/ghostty/themes/noctalia from the wallpaper palette and reloads
    # ghostty live (SIGUSR2). This `theme` line makes noctalia's apply step a
    # no-op edit (the key is already present) so it only writes the theme file.
    theme = "noctalia";
    background-blur-radius = 25;
    window-decoration = false;
    confirm-close-surface = false;
    font-size = 14;
    mouse-scroll-multiplier = 1;
  };
in

mkModule {
  name = "ghostty";
  category = "development";
  linuxPackages = { pkgs, ... }: [ pkgs.ghostty ];
  darwinExtraConfig = { homebrew.casks = [ "ghostty" ]; };
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
