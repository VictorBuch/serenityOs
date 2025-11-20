{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    home.desktop-environments.common.fuzzel.enable = lib.mkEnableOption "Enables fuzzel home manager";
  };

  config = lib.mkIf config.home.desktop-environments.common.fuzzel.enable {
    programs.fuzzel = {
      enable = true;

      settings = {
        main = {
          font = "JetBrainsMono Nerd Font:weight=bold:size=12";
          line-height = 30;
          width = 40;
          fields = "name,generic,comment,categories,filename,keywords";
          terminal = "ghostty -e";
          prompt = ''"❯   "'';
          layer = "overlay";
          lines = 10;
        };

        colors = {
          # Catppuccin Mocha colors
          background = "1e1e2eaa"; # base with transparency
          text = "cdd6f4ff"; # text
          match = "f38ba8ff"; # red
          selection = "585b70ff"; # surface2
          selection-match = "f38ba8ff"; # red
          selection-text = "cdd6f4ff"; # text
          border = "b4befeff"; # lavender
        };

        border = {
          radius = 10;
          width = 2;
        };
      };
    };
  };
}
