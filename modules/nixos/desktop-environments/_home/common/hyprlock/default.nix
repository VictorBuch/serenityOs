{ config, lib, osConfig ? { }, ... }:
{

  options = {
    home.desktop.common.hyprlock.enable = lib.mkEnableOption "Enables Hyprlock";
  };

  config = lib.mkIf config.home.desktop.common.hyprlock.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          ignore_empty_input = true;
        };
        # Background managed by stylix - commented out manual config
        # background = [
        #     {
        #       path = "${config.wallpaper}";
        #       blur_passes = 3;
        #       blur_size = 8;
        #     }
        # ];
        label = [
          {
            #clock
            text = "cmd[update:1000] echo '$TIME'";
            color = "rgba(200, 200, 200, 1.0)";
            font_size = 55;
            font_family = osConfig.fonts.mono.family;
            position = "-100, 70";
            halign = "right";
            valign = "bottom";
            shadow_passes = 5;
            shadow_size = 10;
          }
          {
            text = "$USER";
            color = "rgba(200, 200, 200, 1.0)";
            font_size = 20;
            font_family = osConfig.fonts.mono.family;
            position = "-100, 160";
            halign = "right";
            valign = "bottom";
            shadow_passes = 5;
            shadow_size = 10;
          }
        ];
      };
    };
  };
}
