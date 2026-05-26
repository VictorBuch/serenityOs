{
  config,
  lib,
  pkgs,
  ...
}:
let
  colors = config.lib.stylix.colors.withHashtag;

  rasiTheme = pkgs.writeText "serenity.rasi" ''
    * {
      bg:           ${colors.base00}cc;
      bg-alt:       ${colors.base01}e6;
      bg-selected:  ${colors.base0D};
      fg:           ${colors.base05};
      fg-muted:     ${colors.base04};
      accent:       ${colors.base0D};
      urgent:       ${colors.base08};
      border-col:   ${colors.base02}80;

      background-color: transparent;
      text-color:       @fg;
      font:             "Inter Medium 12";
    }

    window {
      transparency: "real";
      location: center;
      anchor:   center;
      width:    640px;
      border:           1px;
      border-color:     @border-col;
      border-radius:    16px;
      background-color: @bg;
      padding:          0;
    }

    mainbox {
      enabled:  true;
      spacing:  0;
      padding:  0;
      children: [ "inputbar", "message", "listview", "mode-switcher" ];
    }

    inputbar {
      enabled: true;
      spacing: 12px;
      margin:  0;
      padding: 18px 22px;
      border:  0 0 1px 0;
      border-color: @border-col;
      background-color: transparent;
      children: [ "prompt", "entry" ];
    }

    prompt {
      enabled: true;
      text-color: @accent;
    }

    entry {
      enabled: true;
      placeholder: "Search…";
      placeholder-color: @fg-muted;
      text-color: @fg;
    }

    message { padding: 10px 22px; border: 0 0 1px 0; border-color: @border-col; }
    textbox { text-color: @fg; }

    listview {
      enabled: true;
      columns: 1;
      lines:   8;
      cycle:   true;
      dynamic: true;
      scrollbar: false;
      spacing: 4px;
      padding: 10px 10px;
      background-color: transparent;
    }

    element {
      enabled: true;
      spacing: 12px;
      padding: 10px 14px;
      border-radius: 10px;
      background-color: transparent;
      text-color: @fg;
    }

    element selected.normal {
      background-color: @bg-selected;
      text-color: ${colors.base00};
    }

    element-icon {
      size: 1.4em;
      background-color: transparent;
    }

    element-text {
      vertical-align: 0.5;
      text-color: inherit;
      background-color: transparent;
    }

    mode-switcher {
      enabled: true;
      spacing: 0;
      padding: 6px;
      border:  1px 0 0 0;
      border-color: @border-col;
      background-color: transparent;
    }

    button {
      padding: 8px 12px;
      border-radius: 8px;
      text-color: @fg-muted;
      background-color: transparent;
    }

    button selected {
      text-color: ${colors.base00};
      background-color: @accent;
    }
  '';
in
{
  options = {
    home.desktop-environments.common.rofi.enable =
      lib.mkEnableOption "Rofi (wayland) — launcher + community plugins";
  };

  config = lib.mkIf config.home.desktop-environments.common.rofi.enable {
    # Custom theme already pulls stylix colors directly — disable auto-target.
    stylix.targets.rofi.enable = false;

    home.packages = with pkgs; [
      rofi-vpn            # NetworkManager VPN toggle
      rofi-power-menu     # power/lock menu modi script
      rofi-bluetooth      # bluetooth devices
      rofi-network-manager # wifi + ethernet
      rofi-pulse-select   # audio sink/source switcher
      rofi-screenshot     # screenshot menu
      libqalculate        # qalc backend — currency + scientific calc for rofi-calc
    ];

    # Cache currency exchange rates daily so rofi-calc currency conversions
    # work offline and don't hit the network on every invocation.
    systemd.user.services.qalc-exrates = {
      Unit.Description = "Refresh libqalculate currency exchange rates";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.libqalculate}/bin/qalc -e exrates";
      };
    };
    systemd.user.timers.qalc-exrates = {
      Unit.Description = "Daily refresh of libqalculate currency exchange rates";
      Timer = {
        OnBootSec = "5min";
        OnUnitActiveSec = "1d";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

    programs.rofi = {
      enable = true;
      package = pkgs.rofi;
      plugins = with pkgs; [
        rofi-calc
        rofi-emoji
      ];
      terminal = "${pkgs.ghostty}/bin/ghostty";

      extraConfig = {
        modi = "drun,run,calc,window,emoji,power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
        show-icons = true;
        icon-theme = "WhiteSur-icon-theme-dark";
        display-drun = "  Apps";
        display-run = "  Run";
        display-calc = "  Calc";
        display-window = "  Windows";
        display-emoji = "  Emoji";
        display-power-menu = "  Power";
        drun-display-format = "{name}";
        sidebar-mode = true;
        kb-cancel = "Escape";
        # rofi-calc: copy result on Enter
        calc-command = "echo -n '{result}' | wl-copy";
      };

      theme = "${rasiTheme}";
    };
  };
}
