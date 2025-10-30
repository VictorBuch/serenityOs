args@{ config, pkgs, lib, mkHomeModule, ... }:

mkHomeModule {
  _file = toString ./.;
  name = "kitty";
  description = "Kitty terminal emulator";
  homeConfig = { config, pkgs, lib, ... }: {
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
        foreground = "#CAD3F5";
        background = "#24273A";
        linux_display_server = "wayland";
      };
    };
  };
} args
