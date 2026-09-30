{
  config,
  options,
  osConfig,
  lib,
  ...
}:

let
  apps = config.home.desktop.apps;
  shell = lib.mapAttrs (_: lib.escapeShellArgs) config.home.desktop.shell.actions;
  session = osConfig.desktop.session;
  lua = lib.generators.toLua { };

  slots = [
    {
      key = "1";
      ws = "1";
      app = apps.zen;
    }
    {
      key = "2";
      ws = "2";
      app = apps.ghostty;
    }
    {
      key = "3";
      ws = "3";
      app = apps.figma;
    }
    {
      key = "4";
      ws = "4";
      app = apps.obsidian;
    }
    {
      key = "A";
      ws = "5";
      app = apps.android-studio;
    }
    {
      key = "R";
      ws = "6";
      app = apps.reaper;
    }
  ];

  scratchpads = {
    M = apps.sone;
    D = apps.discord;
    S = apps.slack;
  };

  size =
    r:
    let
      dim = v: axis: if v <= 1 then "monitor_${axis}*${toString v}" else toString v;
    in
    "${dim r.width "w"} ${dim r.height "h"}";

  windowRule =
    r:
    "hl.window_rule(${
      lua (
        {
          match =
            lib.optionalAttrs (r.appId != null) { class = r.appId; }
            // lib.optionalAttrs (r.title != null) { inherit (r) title; };
          inherit (r) float;
        }
        // lib.optionalAttrs (r.float && r.width != null && r.height != null) {
          size = size r;
          center = true;
        }
      )
    })";

  bind = keys: dispatch: "hl.bind(${lua keys}, ${dispatch})";
  exec = cmd: "hl.dsp.exec_cmd(${lua cmd})";

  autostart =
    [ config.home.desktop.shell.start ]
    ++ session.autostart
    ++ map (name: [ apps.${name}.command ]) (
      lib.filter (name: apps.${name}.command != (lib.head slots).app.command) session.autostartApps
    );
in
{
  options.home.desktop.compositor.hyprland.enable = lib.mkEnableOption "Hyprland home config";

  config = lib.mkIf config.home.desktop.compositor.hyprland.enable {

    home.liveSeams.hyprland.path = ".config/hypr/local.lua";

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      package = null;
      portalPackage = null;
      systemd.variables = options.wayland.windowManager.hyprland.systemd.variables.default ++ [
        "QT_QPA_PLATFORMTHEME"
      ];

      extraConfig = lib.concatStringsSep "\n" (
        [
          ''hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")''
        ]
        ++ map (
          o:
          "hl.monitor(${
            lua {
              output = o.name;
              mode = "${toString o.width}x${toString o.height}@${toString o.refresh}";
              position = "${toString o.x}x${toString o.y}";
              scale = toString o.scale;
            }
          })"
        ) session.outputs
        ++ [
          "hl.config(${
            lua {
              input = {
                kb_layout = lib.concatStringsSep "," session.input.layouts;
                repeat_delay = session.input.repeatDelay;
                repeat_rate = session.input.repeatRate;
                follow_mouse = 1;
                sensitivity = session.input.touchpad.accelSpeed;
                touchpad = {
                  tap_to_click = session.input.touchpad.tap;
                  natural_scroll = session.input.touchpad.naturalScroll;
                };
              };
              general = {
                gaps_in = 4;
                gaps_out = 4;
                border_size = 2;
                layout = "dwindle";
              };
              decoration = {
                rounding = 8;
                inactive_opacity = 0.9;
                blur = {
                  enabled = true;
                  size = 4;
                  passes = 2;
                };
              };
              misc = {
                disable_hyprland_logo = true;
                focus_on_activate = true;
              };
            }
          })"
          ''hl.on("hyprland.start", function()''
        ]
        ++ map (cmd: "  hl.exec_cmd(${lua (lib.escapeShellArgs cmd)})") autostart
        ++ [ "end)" ]

        ++ lib.concatMap (s: [
          "hl.window_rule(${
            lua {
              match.class = s.app.regex;
              workspace = "${s.ws} silent";
            }
          })"
          "hl.workspace_rule(${
            lua {
              workspace = s.ws;
              layout = "monocle";
              on_created_empty = s.app.command;
            }
          })"
          (bind "SUPER + ${s.key}" "hl.dsp.focus(${lua { workspace = s.ws; }})")
          (bind "SUPER + SHIFT + ${s.key}" "hl.dsp.window.move(${lua { workspace = s.ws; }})")
        ]) slots

        ++ lib.concatLists (
          lib.mapAttrsToList (key: app: [
            "hl.window_rule(${
              lua {
                match.class = app.regex;
                workspace = "special:${app.command} silent";
              }
            })"
            "hl.workspace_rule(${
              lua {
                workspace = "special:${app.command}";
                on_created_empty = app.command;
              }
            })"
            (bind "SUPER + ${key}" "hl.dsp.workspace.toggle_special(${lua app.command})")
          ]) scratchpads
        )

        ++ map windowRule (lib.filter (r: r.float != null) config.home.desktop.windowRules)

        ++ [
          (bind "SUPER + Return" "hl.dsp.focus(${lua { workspace = "2"; }})")
          (bind "SUPER + SHIFT + Return" (exec apps.ghostty.command))
          (bind "SUPER + B" "hl.dsp.focus(${lua { workspace = "1"; }})")
          (bind "SUPER + E" (exec apps.${session.fileManager}.command))
          (bind "SUPER + space" (exec shell.launcher))
          (bind "SUPER + C" (exec "notes-capture"))
          (bind "SUPER + SHIFT + C" (exec shell.launcher-calc))
          (bind "SUPER + Z" (exec shell.launcher-windows))
          (bind "SUPER + SHIFT + E" (exec shell.launcher-emoji))
          (bind "SUPER + SHIFT + P" (exec shell.session-menu))
          (bind "SUPER + P" (exec "skwd wall toggle"))
          (bind "SUPER + N" (exec "rofi-vpn"))
          (bind "SUPER + Y" (exec "handy --toggle-transcription"))

          (bind "SUPER + Q" "hl.dsp.window.close()")
          (bind "SUPER + G" ''hl.dsp.window.float({ action = "toggle" })'')
          (bind "SUPER + F" ''hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'')
          (bind "SUPER + period" "hl.dsp.window.cycle_next()")

          (bind "SUPER + H" ''hl.dsp.focus({ direction = "left" })'')
          (bind "SUPER + L" ''hl.dsp.focus({ direction = "right" })'')
          (bind "SUPER + J" ''hl.dsp.focus({ direction = "down" })'')
          (bind "SUPER + K" ''hl.dsp.focus({ direction = "up" })'')
          (bind "SUPER + SHIFT + H" ''hl.dsp.window.swap({ direction = "left" })'')
          (bind "SUPER + SHIFT + L" ''hl.dsp.window.swap({ direction = "right" })'')
          (bind "SUPER + SHIFT + J" ''hl.dsp.window.swap({ direction = "down" })'')
          (bind "SUPER + SHIFT + K" ''hl.dsp.window.swap({ direction = "up" })'')

          (bind "SUPER + Tab" ''hl.dsp.focus({ workspace = "9" })'')
          (bind "SUPER + SHIFT + Tab" ''hl.dsp.window.move({ workspace = "9" })'')

          (bind "SUPER + ALT + space" (exec "hyprctl switchxkblayout all next"))
          (bind "SUPER + Escape" (exec shell.lock))
          (bind "SUPER + SHIFT + Escape" (exec shell.lock-and-suspend))
          (bind "SUPER + SHIFT + BackSpace" "hl.dsp.exit()")
          (bind "ALT + SHIFT + 4" (exec shell.screenshot-region))
          (bind "ALT + SHIFT + 5" (exec shell.screenshot-fullscreen))

          ''hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })''
          ''hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })''

          ''hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%+"), { locked = true, repeating = true })''
          ''hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%-"), { locked = true, repeating = true })''
          ''hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true })''
          ''hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })''
          ''hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true, repeating = true })''
          ''hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })''
          ''hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })''
          ''hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })''
          ''hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })''
          ''hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })''

          ''local ok, noctalia = pcall(function() return require("noctalia") end)''
          "if ok then noctalia.apply_theme() end"
          ''pcall(require, "local")''
        ]
      );
    };
  };
}
