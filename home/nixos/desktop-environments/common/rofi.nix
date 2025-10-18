{
  config,
  options,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.lib.formats.rasi) mkLiteral;
in
{
  options = {
    home.desktop-environments.common.rofi.enable = lib.mkEnableOption "Enables rofi home manager";
  };

  config = lib.mkIf config.home.desktop-environments.common.rofi.enable {
    programs.rofi = {
      enable = true;

      # Set terminal for applications that require it
      terminal = "${pkgs.ghostty}/bin/ghostty";

      # Add and configure plugins
      plugins = with pkgs; [
        rofi-calc
        rofi-emoji
        rofi-bluetooth
        rofi-power-menu
        rofi-vpn
        rofi-obsidian
        rofi-pulse-select
        rofi-pass-wayland
      ];

      # Configure basic Rofi settings
      extraConfig = {
        modi = "drun,run,ssh,emoji,calc,obsidian:rofi-obsidian";
        show-icons = true;
        icon-theme = "Papirus-Dark";
        display-drun = "Applications";
        display-run = "Run";
        display-ssh = "SSH";
        display-emoji = "Emoji";
        display-calc = "Calculator";
        display-obsidian = "Obsidian";
        drun-display-format = "{name}";
        window-format = "{w} · {c} · {t}";
        combi-modi = "drun,run,emoji,calc";
        combi-hide-mode-prefix = true;
      };

      # Catppuccin Mocha inspired theme with HyDE layout
      theme = {
        "*" = {
          font = "JetBrainsMono Nerd Font 12";

          # Catppuccin Mocha color palette
          bg0 = mkLiteral "#1e1e2e"; # base
          bg1 = mkLiteral "#181825"; # mantle
          bg2 = mkLiteral "#11111b"; # crust
          fg0 = mkLiteral "#cdd6f4"; # text
          fg1 = mkLiteral "#bac2de"; # subtext1
          fg2 = mkLiteral "#a6adc8"; # subtext0
          red = mkLiteral "#f38ba8"; # red
          green = mkLiteral "#a6e3a1"; # green
          yellow = mkLiteral "#f9e2af"; # yellow
          blue = mkLiteral "#89b4fa"; # blue
          magenta = mkLiteral "#cba6f7"; # mauve
          cyan = mkLiteral "#94e2d5"; # teal

          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg0";
          margin = 0;
          padding = 0;
          spacing = 0;
        };

        "window" = {
          location = mkLiteral "center";
          anchor = mkLiteral "center";
          fullscreen = false;
          width = mkLiteral "75em";
          height = mkLiteral "31em";
          x-offset = mkLiteral "0px";
          y-offset = mkLiteral "0px";

          enabled = true;
          margin = mkLiteral "0px";
          padding = mkLiteral "0px";
          border = mkLiteral "2px solid";
          border-radius = mkLiteral "12px";
          border-color = mkLiteral "@magenta";
          background-color = mkLiteral "@bg0";
          cursor = "default";
        };

        "mainbox" = {
          enabled = true;
          spacing = mkLiteral "0px";
          margin = mkLiteral "0px";
          padding = mkLiteral "20px";
          border = mkLiteral "0px solid";
          border-radius = mkLiteral "0px 0px 0px 0px";
          border-color = mkLiteral "@magenta";
          background-color = mkLiteral "transparent";
          children = map mkLiteral [
            "inputbar"
            "listview"
            "mode-switcher"
          ];
        };

        "inputbar" = {
          enabled = true;
          spacing = mkLiteral "10px";
          margin = mkLiteral "0px 0px 20px 0px";
          padding = mkLiteral "15px 20px";
          border = mkLiteral "0px solid";
          border-radius = mkLiteral "10px";
          border-color = mkLiteral "@magenta";
          background-color = mkLiteral "@bg1";
          text-color = mkLiteral "@fg0";
          children = map mkLiteral [
            "textbox-prompt-colon"
            "entry"
          ];
        };

        "prompt" = {
          enabled = true;
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };

        "textbox-prompt-colon" = {
          enabled = true;
          expand = false;
          str = " ";
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };

        "entry" = {
          enabled = true;
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
          cursor = mkLiteral "text";
          placeholder = "Search Applications";
          placeholder-color = mkLiteral "@fg2";
        };

        "listview" = {
          enabled = true;
          columns = 3;
          lines = 4;
          cycle = true;
          dynamic = true;
          scrollbar = false;
          layout = mkLiteral "vertical";
          reverse = false;
          fixed-height = true;
          fixed-columns = true;

          spacing = mkLiteral "10px";
          margin = mkLiteral "0px";
          padding = mkLiteral "0px";
          border = mkLiteral "0px solid";
          border-radius = mkLiteral "0px";
          border-color = mkLiteral "@magenta";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg0";
          cursor = "default";
        };

        "scrollbar" = {
          handle-width = mkLiteral "5px";
          handle-color = mkLiteral "@magenta";
          border-radius = mkLiteral "10px";
          background-color = mkLiteral "@bg2";
        };

        "element" = {
          enabled = true;
          spacing = mkLiteral "10px";
          margin = mkLiteral "0px";
          padding = mkLiteral "20px 10px";
          border = mkLiteral "0px solid";
          border-radius = mkLiteral "10px";
          border-color = mkLiteral "@magenta";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg0";
          orientation = mkLiteral "vertical";
          cursor = mkLiteral "pointer";
        };

        "element normal.normal" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg0";
        };

        "element selected.normal" = {
          background-color = mkLiteral "@bg2";
          text-color = mkLiteral "@magenta";
          border = mkLiteral "2px solid";
          border-color = mkLiteral "@magenta";
        };

        "element-icon" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
          size = mkLiteral "48px";
          cursor = mkLiteral "inherit";
        };

        "element-text" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
          expand = true;
          horizontal-align = mkLiteral "0.5";
          vertical-align = mkLiteral "0.5";
          margin = mkLiteral "5px 0px 0px 0px";
          cursor = mkLiteral "inherit";
        };

        "mode-switcher" = {
          enabled = true;
          spacing = mkLiteral "10px";
          margin = mkLiteral "20px 0px 0px 0px";
          padding = mkLiteral "0px";
          border = mkLiteral "0px solid";
          border-radius = mkLiteral "0px";
          border-color = mkLiteral "@magenta";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg0";
        };

        "button" = {
          padding = mkLiteral "10px 15px";
          border = mkLiteral "0px solid";
          border-radius = mkLiteral "8px";
          border-color = mkLiteral "@magenta";
          background-color = mkLiteral "@bg1";
          text-color = mkLiteral "@fg0";
          cursor = mkLiteral "pointer";
        };

        "button selected" = {
          background-color = mkLiteral "@magenta";
          text-color = mkLiteral "@bg0";
        };
      };
    };
  };
}
