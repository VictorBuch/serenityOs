{
  lib,
  config,
  pkgs,
  ...
}:

let
  terminal = "ghostty";
  fileManager = "nautilus";
  browser = "zen-beta";
  wallpaperDaemon = "awww";
  shell = "noctalia-shell";
in

{

  options = {
    home.desktop-environments.hyprland.enable = lib.mkEnableOption "Enables hyprland home manager";
  };

  config = lib.mkIf config.home.desktop-environments.hyprland.enable {

    home.sessionVariables.NIXOS_OZONE_WL = "1";

    # GNOME Keyring's SSH agent can't handle FIDO2/SK signing — defer to real ssh-agent
    home.sessionVariables.GSM_SKIP_SSH_AGENT_WORKAROUND = "1";
    xdg.configFile."autostart/gnome-keyring-ssh.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Hidden=true
    '';

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      settings = {
        "$mainMod" = "SUPER";

        monitor = [
          "DP-1,2560x1440@144,auto,1.5"
          "Virtual-1,2560x1600@60,auto,1.1"
          ",preferred,auto,1"
        ];

        env = [
          "XCURSOR_SIZE,16"
          "HYPRCURSOR_SIZE,16"
        ];

        general = {
          gaps_in = 4;
          gaps_out = 8;
          border_size = 0;
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        dwindle = {
          # pseudotile removed as a dwindle option in Hyprland 0.55 — use the
          # `pseudo` dispatcher (Mod+P here) to toggle pseudo on a window instead.
          preserve_split = true;
        };

        decoration = {
          rounding = 4;
          active_opacity = 1.0;
          inactive_opacity = 0.95;

          shadow = {
            enabled = true;
            range = 6;
            render_power = 2;
          };

          blur = {
            enabled = true;
            size = 8;
            passes = 2;
            vibrancy = 0.3;
            new_optimizations = true;
            xray = false;
          };
        };

        animations = {
          enabled = true;
          bezier = [
            "easeOutQuad,0.25,1,0.5,1"
            "quick,0.15,0,0.1,1"
          ];
          animation = [
            "windows, 1, 1, easeOutQuad"
            "windowsIn, 1, 1, easeOutQuad, popin 90%"
            "windowsOut, 1, 1, easeOutQuad, popin 90%"
            "fade, 1, 1, quick"
            "workspaces, 1, 1.2, quick, slide"
            "specialWorkspace, 1, 1.2, quick, slidefadevert"
          ];
        };

        input = {
          kb_layout = "us,dk,cz";
          kb_options = "";
          repeat_delay = 200;
          repeat_rate = 35;
          follow_mouse = 1;
          sensitivity = 0;
          touchpad = {
            natural_scroll = true;
            tap-to-click = true;
          };
        };

        # Special workspaces (Sway-style scratchpads) — hidden until summoned.
        # Window rules below auto-route chat/music/game apps here.
        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizeactive"
        ];

        bind = [
          # Launchers
          "$mainMod, Return, exec, ${terminal}"
          "$mainMod, B, exec, ${browser}"
          "$mainMod, F, exec, ${fileManager}"

          # Raycast-style focus-or-run (matches niri Mod+1/2/3/T/D)
          "$mainMod, 1, exec, focus-or-run-hypr zen-beta ${browser}"
          "$mainMod, 2, exec, focus-or-run-hypr com.mitchellh.ghostty ${terminal}"
          "$mainMod, 3, exec, focus-or-run-hypr Slack slack"
          "$mainMod, T, exec, focus-or-run-hypr tidal-hifi tidal-hifi"
          "$mainMod, D, exec, focus-or-run-hypr discord discord"

          # Noctalia shell controls
          "$mainMod, Space, exec, ${shell} ipc call launcher toggle"
          "$mainMod, Comma, exec, ${shell} ipc call settings toggle"
          "$mainMod, Escape, exec, ${shell} ipc call lockScreen lock"
          "$mainMod SHIFT, Escape, exec, ${shell} ipc call sessionMenu lockAndSuspend"

          # Window management
          "$mainMod, Tab, workspace, previous"
          "$mainMod, G, togglefloating,"
          "$mainMod, Q, killactive,"
          "$mainMod SHIFT, F, fullscreen,"
          "$mainMod, V, resizeactive, -100 0"
          "$mainMod SHIFT, V, resizeactive, 100 0"
          "$mainMod, Period, layoutmsg, togglesplit"

          # Focus movement (vim keys)
          "$mainMod, H, movefocus, l"
          "$mainMod, L, movefocus, r"
          "$mainMod, K, movefocus, u"
          "$mainMod, J, movefocus, d"

          # Window movement
          "$mainMod SHIFT, H, movewindow, l"
          "$mainMod SHIFT, L, movewindow, r"
          "$mainMod SHIFT, K, movewindow, u"
          "$mainMod SHIFT, J, movewindow, d"

          # Move active window to workspace
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"

          # Keyboard layout (us -> dk -> cz)
          "$mainMod SHIFT, Space, exec, hyprctl switchxkblayout all next"

          # Screenshots
          "ALT SHIFT, 4, exec, hyprshot -m region"
          "ALT SHIFT, 5, exec, hyprshot -m window"

          # Media keys → noctalia IPC
          ", XF86AudioRaiseVolume, exec, ${shell} ipc call audio volumeUp"
          ", XF86AudioLowerVolume, exec, ${shell} ipc call audio volumeDown"
          ", XF86AudioMute, exec, ${shell} ipc call audio toggleMute"
          ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ", XF86MonBrightnessUp, exec, ${shell} ipc call brightness up"
          ", XF86MonBrightnessDown, exec, ${shell} ipc call brightness down"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ];

        # Hyprland 0.55: `windowrulev2` was removed. Use `windowrule` with the new
        # `match:<prop> <value>` syntax. Every comma-element needs `<key> <value>`,
        # so boolean effects (float/pin/center) get an explicit `1`.
        windowrule = [
          # Main work apps → workspace 1 (browser + terminal tile side-by-side)
          "workspace 1 silent, match:class ^(zen-beta|zen|firefox)$"
          "workspace 1 silent, match:class ^(com.mitchellh.ghostty|ghostty)$"

          # "Out of way" apps → special workspaces (Sway-style scratchpad)
          # Toggle via Mod+3 / Mod+T / Mod+D focus-or-run, or movetoworkspace bind.
          "workspace special:chat silent, match:class ^([Ss]lack)$"
          "workspace special:chat silent, match:class ^([Dd]iscord)$"
          "workspace special:music silent, match:class ^(tidal-hifi)$"
          "workspace special:games silent, match:class ^(steam)$"
          "workspace special:games silent, match:class ^(steam_app_.*)$"

          # Nautilus float
          "float 1, match:class ^(org.gnome.Nautilus)$"
          "size 1472 968, match:class ^(org.gnome.Nautilus)$"
          "center 1, match:class ^(org.gnome.Nautilus)$"

          # Picture-in-Picture
          "float 1, match:title ^(Picture-in-Picture)$"
          "size 345 200, match:title ^(Picture-in-Picture)$"
          "pin 1, match:title ^(Picture-in-Picture)$"
          "move 100%-365 50, match:title ^(Picture-in-Picture)$"

          # Wine / audio software installers float for dialogs
          "float 1, match:title ^(iLok|PACE|License).*$"
          "float 1, match:title ^(IK Product Manager|IK Multimedia).*$"
        ];

        # Hyprland 0.55 layerrule syntax: each field is `<key> <value>`, comma-separated.
        # Match namespace via `match:namespace <regex>`. `ignorezero` was removed
        # upstream — folded into `ignore_alpha` with threshold 0.
        layerrule = [
          "blur 1, match:namespace wlogout"
          "blur 1, match:namespace notifications"
          "ignore_alpha 0.2, match:namespace wlogout"
          "ignore_alpha 0.2, match:namespace notifications"
        ];

        exec-once = [
          "${wallpaperDaemon}-daemon"
          "${shell}"
          "${terminal}"
          "${browser}"
          "slack"
          "discord"
          "easyeffects --gapplication-service"
          "${wallpaperDaemon} img ${config.wallpaper}"
          "wl-paste --watch cliphist store"
        ];

        ecosystem.no_donation_nag = true;
      };
    };
  };

}
