{
  config,
  osConfig,
  lib,
  ...
}:

let
  apps = config.home.desktop.apps;
  session = osConfig.desktop.session;
  kdlArgs = lib.concatMapStringsSep " " builtins.toJSON;
  shell = lib.mapAttrs (_: kdlArgs) config.home.desktop.shell.actions;
  # Stylix colors for niri (no upstream Stylix target for niri)
  colors = config.lib.stylix.colors.withHashtag;

  num =
    x:
    if builtins.isInt x then
      toString x
    else
      let
        trim = str: if lib.hasSuffix "0" str then trim (lib.removeSuffix "0" str) else str;
      in
      lib.removeSuffix "." (trim (toString x));
  size = x: if x <= 1 then "proportion ${num x}" else "fixed ${num x}";

  outputs = lib.concatMapStrings (o: ''
    output "${o.name}" {
        mode "${toString o.width}x${toString o.height}@${num o.refresh}"
        scale ${num o.scale}
        position x=${toString o.x} y=${toString o.y}
    }
  '') session.outputs;

  windowRules = lib.concatMapStrings (
    r:
    let
      body = lib.concatStrings (
        lib.optional (r.float != null) "    open-floating ${lib.boolToString r.float}\n"
        ++ lib.optional (r.width != null) "    default-column-width { ${size r.width}; }\n"
        ++ lib.optional (r.height != null) "    default-window-height { ${size r.height}; }\n"
      );
      match = lib.concatStringsSep " " (
        lib.optional (r.appId != null) "app-id=r#\"${r.appId}\"#"
        ++ lib.optional (r.title != null) "title=r#\"${r.title}\"#"
      );
    in
    lib.optionalString (body != "") "window-rule {\n    match ${match}\n${body}}\n"
  ) config.home.desktop.windowRules;

  autostart =
    [ config.home.desktop.shell.start ]
    ++ session.autostart
    ++ map (name: [ apps.${name}.command ]) session.autostartApps;
in

{
  options = {
    home.desktop.compositor.niri.enable = lib.mkEnableOption "Enables niri home manager";
  };

  config = lib.mkIf config.home.desktop.compositor.niri.enable {


    # Write niri config.kdl to ~/.config/niri/
    xdg.configFile."niri/config.kdl".text = ''
      input {
          keyboard {
              xkb {
                  layout "${lib.concatStringsSep "," session.input.layouts}"
              }
              repeat-delay ${toString session.input.repeatDelay}
              repeat-rate ${toString session.input.repeatRate}
          }

          touchpad {
              ${lib.optionalString session.input.touchpad.tap "tap"}
              ${lib.optionalString session.input.touchpad.naturalScroll "natural-scroll"}
              accel-speed ${num session.input.touchpad.accelSpeed}
          }

          mod-key "Super"
      }

        ${outputs}

        // Layout configuration
        layout {
            gaps 4

            struts {
                top 4
                bottom 4
                left 4
                right 4
            }

            focus-ring {
                width 1.5
                active-color "${colors.base04}"
                inactive-color "${colors.base03}"
            }

            border {
                off
            }

            preset-column-widths {
                proportion 0.5
                proportion 0.98
            }

            default-column-width { proportion 0.98; }

            center-focused-column "on-overflow"
            always-center-single-column

            // Transparent background for noctalia wallpapers (Option 2)
            background-color "transparent"
        }

        workspace "scratchpad"
        workspace "main"
        workspace "chat"

        // Key bindings
        binds {
            // Application launchers
            Mod+Return { spawn "${apps.ghostty.command}"; }
            Mod+B { spawn "${apps.zen.command}"; }
            Mod+F { spawn "${session.fileManager}"; }

            // Raycast-style focus-or-run bindings (Alt + numbers)
            Mod+1 { spawn ${kdlArgs [ "focus-or-run" apps.zen.regex apps.zen.command ]}; }
            Mod+2 { spawn ${kdlArgs [ "focus-or-run" apps.ghostty.regex apps.ghostty.command ]}; }
            Mod+3 { spawn ${kdlArgs [ "focus-or-run" apps.slack.regex apps.slack.command ]}; }
            Mod+T { spawn ${kdlArgs [ "focus-or-run" apps.tidal.regex apps.tidal.command ]}; }
            Mod+D { spawn ${kdlArgs [ "focus-or-run" apps.discord.regex apps.discord.command ]}; }

            // Noctalia shell controls
            Mod+Space { spawn ${shell.launcher}; }
            Mod+Comma { spawn ${shell.settings}; }
            Mod+Escape { spawn ${shell.lock}; }
            Mod+Shift+Escape { spawn ${shell.lock-and-suspend}; }

            // Handy's own global hotkey uses the Tauri plugin, which is X11-only —
            // the compositor has to drive it over the CLI instead.
            Mod+Shift+D { spawn "handy" "--toggle-transcription"; }

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
            // Mod+1 { focus-workspace 1; }
            // Mod+2 { focus-workspace 2; }
            // Mod+3 { focus-workspace 3; }
            // Mod+4 { focus-workspace 4; }
            // Mod+5 { focus-workspace 5; }
            // Mod+6 { focus-workspace 6; }
            // Mod+7 { focus-workspace 7; }
            // Mod+8 { focus-workspace 8; }
            // Mod+9 { focus-workspace 9; }

            // Move window to workspace
            Mod+Shift+1 { move-column-to-workspace 1; }
            Mod+Shift+2 { move-column-to-workspace 2; }
            Mod+Shift+3 { move-column-to-workspace 3; }
            // Mod+Shift+4 { move-column-to-workspace 4; }
            // Mod+Shift+5 { move-column-to-workspace 5; }
            // Mod+Shift+6 { move-column-to-workspace 6; }
            // Mod+Shift+7 { move-column-to-workspace 7; }
            // Mod+Shift+8 { move-column-to-workspace 8; }
            // Mod+Shift+9 { move-column-to-workspace 9; }

            // Keyboard layout switching (US -> Danish -> Czech)
            Mod+Shift+Space { switch-layout "next"; }

            // Screenshots
            Alt+Shift+4 { spawn ${shell.screenshot-region}; }
            Alt+Shift+5 { spawn ${shell.screenshot-fullscreen}; }


            // Media keys
            XF86AudioRaiseVolume { spawn ${shell.volume-up}; }
            XF86AudioLowerVolume { spawn ${shell.volume-down}; }
            XF86AudioMute { spawn ${shell.volume-mute}; }
            XF86AudioMicMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
            XF86MonBrightnessUp { spawn ${shell.brightness-up}; }
            XF86MonBrightnessDown { spawn ${shell.brightness-down}; }
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
            geometry-corner-radius 4
            clip-to-geometry true
        }

        // Application workspace assignments
        window-rule {
            match app-id=r#"^org\.wezfurlong\.wezterm$|^dev\.warp\.Warp$|${apps.ghostty.regex}"#
            open-on-workspace "main"
        }
        window-rule {
            match app-id=r#"${apps.zen.regex}"#
            open-on-workspace "main"
        }
        window-rule {
            match app-id=r#"^steam$|^steam_app_.*$"#
            open-on-workspace "scratchpad"
        }
        window-rule {
            match app-id=r#"${apps.discord.regex}"#
            open-on-workspace "chat"
        }
        window-rule {
            match app-id=r#"${apps.slack.regex}"#
            open-on-workspace "chat"
        }
        window-rule {
            match app-id=r#"${apps.tidal.regex}"#
            open-on-workspace "scratchpad"
        }

        ${windowRules}
        window-rule {
          match title=r#"^Picture-in-Picture$"#
          default-floating-position x=0 y=40 relative-to="top"
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

        ${lib.concatMapStrings (cmd: "spawn-at-startup ${kdlArgs cmd}\n") autostart}

        // Animations
        animations {
            slowdown 0.3
            horizontal-view-movement {
                spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
            }
            window-open {
                duration-ms 100
                curve "ease-out-quad"
            }
            window-close {
                duration-ms 100
                curve "ease-out-quad"
            }
        }

        // Environment variables

        // Xwayland support (integrated since niri 25.08)
        xwayland-satellite {
            // xwayland-satellite will automatically start and manage X11 apps
        }

        // Prefer dark themes
        prefer-no-csd


        clipboard {
            disable-primary
        }

        hotkey-overlay {
            skip-at-startup
        }

    '';
  };
}
