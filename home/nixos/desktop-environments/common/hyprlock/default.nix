{ config, lib, ... }:
{

  options = {
    home.desktop-environments.common.hyprlock.enable = lib.mkEnableOption "Enables Hyprlock";
  };

  config = lib.mkIf config.home.desktop-environments.common.hyprlock.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
            ignore_empty_input = true;
        };
        background = [
            {
              path = "${config.wallpaper}";
              blur_passes = 3;
              blur_size = 8;
            }
        ];
        label =[ {
            #clock
            text = "cmd[update:1000] echo '$TIME'";
            color = "rgba(200, 200, 200, 1.0)";
            font_size = 55;
            font_family = "JetBrainsMono Nerd Font";
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
            font_family = "JetBrainsMono Nerd Font";
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
