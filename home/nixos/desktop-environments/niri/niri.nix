{
  config,
  pkgs,
  lib,
  ...
}:

let
  terminal = "ghostty";
  fileManager = "nautilus";
  browser = "zen";
  wallpaperDaemon = "swww";
  shell = "noctalia-shell";
  applicationLauncher = "fuzzel";
in

{
  options = {
    home.desktop-environments.niri.enable = lib.mkEnableOption "Enables niri home manager";
  };

  config = lib.mkIf config.home.desktop-environments.niri.enable {

    # Set Wayland environment variable
    home.sessionVariables.NIXOS_OZONE_WL = "1";

    # Write niri config.kdl to ~/.config/niri/
    xdg.configFile."niri/config.kdl".text = ''
      // Input configuration
      input {
          // Focus windows automatically when moving the mouse into them.
          // max-scroll-amount="95%" means focus won't switch if it requires scrolling more than 95%
          // (i.e., only focus windows that are at least 5% visible)
          // focus-follows-mouse max-scroll-amount="75%"

          keyboard {
              xkb {
                  layout "us"
              }
              repeat-delay 200
              repeat-rate 35
          }

            touchpad {
                tap
                natural-scroll
                accel-speed 0.2
            }

            // Use Super as the modifier key
            mod-key "Super"
        }

        // Output configuration (monitor setup)
        // Adjust as needed for your specific setup
        // Commented out to allow auto-detection (especially important for VMs)
        output "DP-1" {
            mode "2560x1440@119.998"
        }
        output "Virtual-1" {
            mode "2560x1600@59.972"
            scale 1.25
        } 

        // Layout configuration
        layout {
            gaps 8

            struts {
                top 8
                bottom 8
                left 8
                right 8
            }

            focus-ring {
                width 1.5
                active-color "#aaaaaa"   // Catppuccin Mocha mauve
                inactive-color "#6c7086"  // Catppuccin Mocha surface2
            }

            border {
                off
            }

            preset-column-widths {
                proportion 0.5
                proportion 0.9
            }

            default-column-width { proportion 0.5; }

            center-focused-column = "always"
            always-center-single-column

            // Transparent background for noctalia wallpapers (Option 2)
            background-color "transparent"
        }

        workspace "scratchpad"
        workspace "main"
        workspace "gaming"
        workspace "chat"

        // Key bindings
        binds {
            // Application launchers
            Mod+Return { spawn "${terminal}"; }
            Mod+B { spawn "${browser}"; }
            Mod+F { spawn "${fileManager}"; }

            // Noctalia shell controls
            Mod+Space { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
            Mod+S { spawn "noctalia-shell" "ipc" "call" "controlcenter" "toggle"; }
            Mod+Comma { spawn "noctalia-shell" "ipc" "call" "settings" "toggle"; }
            Mod+Y { spawn "noctalia-shell" "ipc" "call" "clipboard" "toggle"; }
            Mod+C { spawn "noctalia-shell" "ipc" "call" "calculator" "toggle"; }
            Mod+Escape { spawn "noctalia-shell" "ipc" "call" "lockScreen" "lock"; }
            Mod+Shift+Escape { spawn "noctalia-shell" "ipc" "call" "sessionMenu" "lockAndSuspend";}

            // Window management
            Mod+Tab { toggle-overview; }
            Mod+G {toggle-window-floating;}
            Mod+Q { close-window; }
            Mod+Shift+F { fullscreen-window; }
            Mod+V { set-column-width "-10%"; }
            Mod+Shift+V { set-column-width "+10%"; }
            Mod+Period { switch-preset-column-width; }

            // Focus movement (vim keys)
            Mod+H { focus-column-left; }
            Mod+L { focus-column-right; }
            Mod+J { focus-window-or-workspace-down; }
            Mod+K { focus-window-or-workspace-up; }

            // Window movement
            Mod+Shift+H { move-column-left; }
            Mod+Shift+L { move-column-right; }
            Mod+Shift+J { move-column-to-workspace-down; }
            Mod+Shift+K { move-column-to-workspace-up; }

            // Workspace switching
            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }

            // Move window to workspace
            Mod+Shift+1 { move-column-to-workspace 1; }
            Mod+Shift+2 { move-column-to-workspace 2; }
            Mod+Shift+3 { move-column-to-workspace 3; }
            Mod+Shift+4 { move-column-to-workspace 4; }
            Mod+Shift+5 { move-column-to-workspace 5; }
            Mod+Shift+6 { move-column-to-workspace 6; }
            Mod+Shift+7 { move-column-to-workspace 7; }
            Mod+Shift+8 { move-column-to-workspace 8; }
            Mod+Shift+9 { move-column-to-workspace 9; }

            // Screenshots
            Alt+Shift+4 { screenshot; }
            Alt+Shift+5 { screenshot-window; }


            // Media keys (noctalia IPC)
            XF86AudioRaiseVolume { spawn "noctalia-shell" "ipc" "call" "audio" "volumeUp"; }
            XF86AudioLowerVolume { spawn "noctalia-shell" "ipc" "call" "audio" "volumeDown"; }
            XF86AudioMute { spawn "noctalia-shell" "ipc" "call" "audio" "toggleMute"; }
            XF86AudioMicMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
            XF86MonBrightnessUp { spawn "noctalia-shell" "ipc" "call" "brightness" "up"; }
            XF86MonBrightnessDown { spawn "noctalia-shell" "ipc" "call" "brightness" "down"; }
            XF86AudioNext { spawn "playerctl" "next"; }
            XF86AudioPause { spawn "playerctl" "play-pause"; }
            XF86AudioPlay { spawn "playerctl" "play-pause"; }
            XF86AudioPrev { spawn "playerctl" "previous"; }
        }

        // Window rules
        window-rule {
            draw-border-with-background false
        }
        window-rule {
            geometry-corner-radius 20
            clip-to-geometry true
        }

        // Application workspace assignments
        window-rule {
            match app-id=r#"^org\.wezfurlong\.wezterm$|^dev\.warp\.Warp$|^com\.mitchellh\.ghostty$|^ghostty$"#
            open-on-workspace "main"
        }
        window-rule {
            match app-id=r#"^zen-alpha$|^zen$|^firefox$"#
            open-on-workspace "main"
        }
        window-rule {
            match app-id=r#"^steam$|^steam_app_.*$"#
            open-on-workspace "gaming"
        }
        window-rule {
            match app-id=r#"^discord$|^[Dd]iscord$"#
            open-on-workspace "chat"
        }

        // Noctalia wallpaper layer rule (Option 2: Stationary wallpapers)
        layer-rule {
          match namespace="^noctalia-wallpaper*"
          place-within-backdrop true
        }

      // Gestures configuration
      gestures {
          // Disable hot corners (corners that toggle overview when mouse moves to them)
          hot-corners {
              off
          }
      }

      overview {
          workspace-shadow {
              off
          }
      }

        // Spawn at startup
        spawn-at-startup "${shell}"
        spawn-at-startup "${terminal}"
        spawn-at-startup "easyeffects" "--gapplication-service"
        spawn-at-startup "wl-paste" "--watch" "cliphist" "store"

        // Animations
        // animations {
        //     slowdown 1.0
        //     horizontal-view-movement {
        //         spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
        //     }
        //     window-open {
        //         duration-ms 150
        //         curve "ease-out-quad"
        //     }
        //     window-close {
        //         duration-ms 150
        //         curve "ease-out-quad"
        //     }
        // }

        // Environment variables
        environment {
            XCURSOR_SIZE "18"
        }

        // Xwayland support (integrated since niri 25.08)
        xwayland-satellite {
            // xwayland-satellite will automatically start and manage X11 apps
        }

        // Prefer dark themes
        prefer-no-csd

        debug {
          // Allows notification actions and window activation from Noctalia.
          honor-xdg-activation-with-invalid-serial
        }
    '';
  };
}
