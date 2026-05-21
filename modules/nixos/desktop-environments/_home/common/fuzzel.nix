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
          # font managed by stylix
          line-height = 28;
          width = 42;
          fields = "name,generic,comment,categories,filename,keywords";
          terminal = "ghostty -e";
          prompt = ''"❯   "'';
          layer = "overlay";
          lines = 8;
          horizontal-pad = 24;
          vertical-pad = 20;
          inner-pad = 14;
          icon-theme = "WhiteSur-icon-theme-dark";
          dpi-aware = "yes";
        };

        # Colors + background opacity managed by stylix (opacity.popups)

        border = {
          radius = 14;
          width = 1;
        };
      };
    };
  };
}
