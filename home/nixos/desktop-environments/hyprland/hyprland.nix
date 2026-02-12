{
  lib,
  config,
  pkgs,
  ...
}:

let
  terminal = "ghostty";
  fileManager = "nautilus";
  browser = "zen";
  wallpaperDaemon = "swww";
  bar = "hyprpanel";
in

{

  options = {
    home.desktop-environments.hyprland.enable = lib.mkEnableOption "Enables hyprland home manager";
  };

  config = lib.mkIf config.home.desktop-environments.hyprland.enable {

    # programs.kitty.enable = true;
    home.sessionVariables.NIXOS_OZONE_WL = "1";
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mainMod" = "SUPER";
        monitor = ",2560x1440@144,auto,1";
        env = [
          "XCURSOR_SIZE,20"
          "HYPRCURSOR_SIZE,20"
          "HYPRCURSOR_THEME,catppuccin-mocha-light-cursors"
        ];
        general = {
          gaps_in = 4;
          gaps_out = 8;

          border_size = 0;

          # Catppuccin Mocha colors
          # "col.active_border" = "rgb(cba6f7) rgb(f2cdcd) 45deg";
          # "col.inactive_border" = "rgba(6c7086aa)";

          # Set to true enable resizing windows by clicking and dragging on borders and gaps
          resize_on_border = false;

          # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
          allow_tearing = false;

          layout = "dwindle";
        };
        decoration = {
          rounding = 4;
          # Change transparency of focused and unfocused windows
          active_opacity = 0.99;
          inactive_opacity = 0.80;

          shadow = {
            enabled = true;
            range = 6;
            render_power = 2;
          };

          # https://wiki.hyprland.org/Configuring/Variables/#blur
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
            "easeOutQuint,0.23,1,0.32,1"
            "easeInOutCubic,0.65,0.05,0.36,1"
            "linear,0,0,1,1"
            "almostLinear,0.5,0.5,0.75,1.0"
            "quick,0.15,0,0.1,1"
          ];

          animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 4.79, easeOutQuint"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "windowsOut, 1, 1.49, linear, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 1, 1.94, quick, fade"
            "workspacesIn, 1, 1.21, quick, fade"
            "workspacesOut, 1, 1.94, quick, fade"
          ];
        };
        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizeactive"
        ];
        bind = [
          "$mainMod, RETURN, exec, ${terminal}"
          "$mainMod, B, exec, ${browser}"
          "$mainMod, Q, killactive,"
          "$mainMod, F, exec, ${fileManager}"
          "$mainMod SHIFT, F, fullscreen"
          "$mainMod, V, togglefloating,"
          "$mainMod, P, pseudo,"
          "$mainMod SHIFT, J, togglesplit,"
          "$mainMod SHIFT, L, exec, hyprlock"

          # screen shot
          "CONTROL ALT, 4, exec, hyprshot -m region"
          "CONTROL ALT, 5, exec, hyprshot -m window"

          # Move focus with mainMod + arrow keys
          "$mainMod, h, movefocus, l"
          "$mainMod, l, movefocus, r"
          "$mainMod, k, movefocus, u"
          "$mainMod, j, movefocus, d"

          # Switch workspaces with mainMod + [0-9]
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"

          # Example special workspace (scratchpad)
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          # Scroll through existing workspaces with mainMod + scroll
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"

          # Laptop multimedia keys for volume and LCD brightness
          ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
          ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"

          # Requires playerctl
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"

        ];
        exec-once = [
          "${wallpaperDaemon}-daemon"
          "${bar}"
          "${terminal}"
          "${browser}"
          # "hyprpaper"
          "easyeffects --gapplication-service"
          "${wallpaperDaemon} img ${config.wallpaper}"
          "wl-paste --watch cliphist store" # Clipboard history
        ];
        input = {
          kb_layout = [ "us" ];
          kb_options = "grp:alt_space_toggle";

          follow_mouse = 1;

          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

          touchpad = {
            natural_scroll = true;
          };
        };

        windowrulev2 = [
          "workspace 1, class:^(zen-beta)$"
          "workspace 2, class:^(kitty)$"
          "workspace 2, class:^(com.mitchellh.ghostty)$"
          "workspace 3, class:^(code)$"
          "workspace 1, class:^(firefox)$"
          "workspace 4, class:^(spotify)$"
          "workspace 4, class:^(slack)$"
          "workspace 5, class:^(steam)$"
          "float, class:^(org.gnome.Nautilus)$"
          "size 1472 968, class:^(org.gnome.Nautilus)$"
          "center, class:^(org.gnome.Nautilus)$"
        ];
        layerrule = [
          "blur, wlogout"
          "blur, notifications"
          "ignorezero, wlogout"
          "ignorezero, notifications"
          "ignorealpha 0.2, wlogout"
          "ignorealpha 0.2, notifications"
        ];
        ecosystem.no_donation_nag = true;
      };
    };
  };

}
