{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    home.desktop-environments.common.dunst.enable = lib.mkEnableOption "Enables dunst home manager";
  };

  config = lib.mkIf config.home.desktop-environments.common.dunst.enable {
    services.dunst = {
      enable = true;
      settings = {
        global = {
          # Display
          monitor = 0;
          follow = "mouse";

          # Geometry
          width = 320;
          height = 200;
          origin = "top-right";
          offset = "16x16";
          scale = 0;
          notification_limit = 5;

          # Progress bar
          progress_bar = true;
          progress_bar_height = 8;
          progress_bar_frame_width = 1;
          progress_bar_min_width = 150;
          progress_bar_max_width = 300;
          progress_bar_corner_radius = 4;

          # Text styling

          line_height = 0;
          markup = "full";
          format = "<b>%s</b>\\n%b";
          alignment = "left";
          vertical_alignment = "center";
          show_age_threshold = 60;
          ellipsize = "middle";
          ignore_newline = false;
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = true;

          # Icons
          enable_recursive_icon_lookup = true;
          icon_theme = "Papirus-Dark";
          icon_position = "left";
          min_icon_size = 24;
          max_icon_size = 48;
          icon_path = "/usr/share/icons/gnome/16x16/status/:/usr/share/icons/gnome/16x16/devices/";

          # History
          sticky_history = true;
          history_length = 20;

          # Misc/Advanced
          browser = "zen";
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          corner_radius = 12;
          ignore_dbusclose = false;

          # Mouse
          mouse_left_click = "close_current";
          mouse_middle_click = "do_action, close_current";
          mouse_right_click = "close_all";
        };

        experimental = {
          per_monitor_dpi = false;
        };

        urgency_low = {
          timeout = 3;
          override_pause_level = 30;
        };

        urgency_normal = {
          timeout = 6;
          override_pause_level = 30;
        };

        urgency_critical = {
          timeout = 0;
          override_pause_level = 60;
        };
      };
    };
  };
}
