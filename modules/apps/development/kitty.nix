args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "kitty";
  category = "development";
  packages = { pkgs, ... }: [ pkgs.kitty ];
  description = "Kitty terminal emulator";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.kitty = {
        enable = true;
        settings = {
          hide_window_decorations = "yes";
          remember_window_size = "yes";
          initial_window_width = 2920;
          initial_window_height = 2080;
          window_padding_width = 8;
          confirm_os_window_close = 0;
          term = "xterm-256color";
          # Colors come from noctalia's `kitty` template (themes/noctalia.conf).
          linux_display_server = "wayland";
        };
        # noctalia writes ~/.config/kitty/themes/noctalia.conf from the wallpaper
        # palette; this include makes those colors take effect (kitty live-reloads).
        extraConfig = ''
          include themes/noctalia.conf
        '';
      };
    };
} args
