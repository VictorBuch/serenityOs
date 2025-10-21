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

      # Custom theme
      theme = {
        "*" = {
          font = "JetBrainsMono 12";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "#e5e9f0";
        };

        "window" = {
          location = mkLiteral "center";
          anchor = mkLiteral "center";
          background-color = mkLiteral "rgba(41, 46, 66, 0.5)";
          padding = mkLiteral "10px";
          border-radius = mkLiteral "20px";
          border = mkLiteral "5px solid";
          border-color = mkLiteral "#b072d1";
        };

        "mainbox" = {
          background-color = mkLiteral "transparent";
          padding = mkLiteral "20px";
          children = map mkLiteral [
            "inputbar"
            "listview"
          ];
        };

        "inputbar" = {
          background-color = mkLiteral "transparent";
          padding = mkLiteral "10px";
          margin = mkLiteral "0px 0px 10px 0px";
          border-radius = mkLiteral "15px";
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
          placeholder-color = mkLiteral "#a0a0a0";
        };

        "listview" = {
          enabled = true;
          columns = 1;
          lines = 6;
          cycle = true;
          dynamic = true;
          scrollbar = false;
          layout = mkLiteral "vertical";
          reverse = false;
          fixed-height = true;
          fixed-columns = true;
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "#e5e9f0";
          spacing = mkLiteral "10px";
          padding = mkLiteral "0px";
        };

        "element" = {
          enabled = true;
          spacing = mkLiteral "10px";
          padding = mkLiteral "10px";
          border-radius = mkLiteral "15px";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "#e5e9f0";
          orientation = mkLiteral "vertical";
          cursor = mkLiteral "pointer";
        };

        "element normal.normal" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "#e5e9f0";
        };

        "element selected.normal" = {
          background-color = mkLiteral "#2e3440";
          text-color = mkLiteral "#e5e9f0";
        };

        "element-icon" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
          size = mkLiteral "48px";
          cursor = mkLiteral "inherit";
          margin = mkLiteral "0px 6px 0px 0px";
        };

        "element-text" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
          expand = true;
          horizontal-align = mkLiteral "0.5";
          vertical-align = mkLiteral "0.5";
          margin = mkLiteral "2px";
          cursor = mkLiteral "inherit";
        };

        "mode-switcher" = {
          enabled = true;
          spacing = mkLiteral "10px";
          margin = mkLiteral "20px 0px 0px 0px";
          padding = mkLiteral "0px";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "#e5e9f0";
        };

        "button" = {
          padding = mkLiteral "10px 15px";
          border-radius = mkLiteral "8px";
          background-color = mkLiteral "rgba(41, 46, 66, 0.5)";
          text-color = mkLiteral "#e5e9f0";
          cursor = mkLiteral "pointer";
        };

        "button selected" = {
          background-color = mkLiteral "#b072d1";
          text-color = mkLiteral "#e5e9f0";
        };
      };
    };
  };
}
