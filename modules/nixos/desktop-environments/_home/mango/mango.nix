{
  config,
  pkgs,
  lib,
  ...
}:

let
  terminal = "ghostty";
  fileManager = "thunar";
  browser = "zen-beta";
  shell = "noctalia";
  applicationLauncher = "rofi -show drun";
  calcLauncher = "rofi -show calc -no-show-match -no-sort";
  windowSwitcher = "rofi -show window";
  emojiPicker = "rofi -show emoji";
  powerMenu = "rofi -show power-menu";
  # Window-decoration colors are no longer set here: noctalia's `mango`
  # template writes them to ~/.config/mango/noctalia.conf from the wallpaper
  # palette and reloads mango live. See the `source=` include in extraConfig
  # below and modules/nixos/desktop-environments/_home/common/noctalia.nix.

  # Raycast-style slots — pinned to tag 1.
  tag1Apps = [
    "zen-beta"
    "zen"
    "firefox"
    "com\\.mitchellh\\.ghostty"
    "ghostty"
    "figma-linux"
    "Figma"
    "Obsidian"
    "obsidian"
  ];

  # Named scratchpads — tag-less by design.
  scratchpadApps = [
    "[Dd]iscord"
    "[Ss]lack"
    "sone"
  ];

  # File manager: floats on the current tag.
  thunarApps = [
    "[Tt]hunar"
    "[Tt]hunar-.*"
    "org\\.xfce\\.[Tt]hunar"
  ];

  # Portals and dialog-only helpers: float on the current tag.
  dialogApps = [
    "xdg-desktop-portal.*"
    "org\\.freedesktop\\.impl\\.portal\\..*"
    "zenity"
    "polkit-.*"
    "pavucontrol"
    "\\.?blueman-.*"
    "nm-connection-editor"
    "file-roller"
    "nwg-look"
    "qt[56]ct"
  ];

  # Anything matching these keeps whatever tag it inherits; everything else
  # is swept to tag 2 by the catch-all rule.
  noSweepApps = tag1Apps ++ scratchpadApps ++ thunarApps ++ dialogApps ++ [ "steam" ];

  alternation = lib.concatStringsSep "|";
in

{
  options = {
    home.desktop-environments.mango.enable = lib.mkEnableOption "Enables mango home manager";
  };

  config = lib.mkIf config.home.desktop-environments.mango.enable {

    home.sessionVariables.NIXOS_OZONE_WL = "1";

    home.sessionVariables.GSM_SKIP_SSH_AGENT_WORKAROUND = "1";

    home.sessionVariables.QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
    xdg.configFile."autostart/gnome-keyring-ssh.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Hidden=true
    '';

    wayland.windowManager.mango = {
      enable = true;

      # Pull in noctalia's live-generated color file. noctalia writes
      # ~/.config/mango/noctalia.conf (writable, not HM-managed) from the
      # wallpaper palette and runs `mmsg dispatch reload_config`, so window
      # colors update in real time. mango tolerates the file being absent at
      # build/first-run (parse warns but succeeds).
      extraConfig = ''
        source=~/.config/mango/noctalia.conf
      '';

      autostart_sh = ''
        ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
        ${shell} &
        easyeffects --gapplication-service &
        wl-paste --watch cliphist store &
        ${browser} &
        ${terminal} &
        figma-linux &
      '';

      settings = {
        # === Input ===
        repeat_delay = 200;
        repeat_rate = 35;
        xkb_rules_layout = "us,dk,cz";
        sloppyfocus = 1;
        warpcursor = 0;
        focus_on_activate = 1;

        # Touchpad
        tap_to_click = 1;
        trackpad_natural_scrolling = 1;
        trackpad_accel_speed = 0.2;

        # === Layout / appearance ===
        gappih = 4;
        gappiv = 4;
        gappoh = 4;
        gappov = 4;
        smartgaps = 0;
        no_border_when_single = 1;

        border_radius = 8;
        focused_opacity = 1.0;
        unfocused_opacity = 0.9;

        # === Shadows ===
        shadows = 0;
        layer_shadows = 0;

        # === Blur ===
        blur = 1;
        blur_layer = 1;
        blur_optimized = 1;
        blur_params_num_passes = 2;
        blur_params_radius = 4;
        blur_params_noise = 0.015;
        blur_params_brightness = 0.95;
        blur_params_contrast = 0.95;
        blur_params_saturation = 1.1;

        # Colors (bordercolor/focuscolor/urgentcolor/scratchpadcolor/...) are
        # provided live by noctalia via the sourced noctalia.conf (extraConfig).

        # Master-stack defaults (applies to tile/center_tile)
        new_is_master = 1;
        default_mfact = 0.55;
        default_nmaster = 1;
        center_when_single_stack = 1;

        # Scratchpad sizing
        scratchpad_width_ratio = 1.0;
        scratchpad_height_ratio = 1.0;
        single_scratchpad = 1;

        # Layout cycling — user-requested set
        circle_layout = "fair,scroller,monocle";

        # Scroller defaults — full-width new windows
        scroller_default_proportion = 0.99;
        scroller_structs = 20;
        edge_scroller_pointer_focus = 0;

        # === Misc ===
        xwayland_persistence = 1;
        focus_cross_monitor = 1;
        focus_cross_tag = 0;
        enable_floating_snap = 1;

        # === Environment ===
        env = [
          "XCURSOR_SIZE,16"
        ];

        # === Monitors ===
        monitorrule = [
          "name:^DP-1$,width:2560,height:1440,refresh:144,x:0,y:0,scale:1.2"
          "name:^Virtual-1$,width:2560,height:1600,refresh:60,x:0,y:0,scale:1.1"
        ];

        # === Tag rules: layouts per tag ===
        # Tag 1 = scroller (zen/ghostty/figma side-by-side via SUPER+H/L)
        # Tag 2 = tile (obsidian + overflow)
        # Tag 3 = tile (steam)
        tagrule = [
          "id:1,layout_name:monocle"
          "id:2,layout_name:scroller"
          "id:3,layout_name:scroller"
        ];

        # === Window rules ===
        windowrule = [
          # Raycast-style slots: pin appid → tag so focus-or-run lands consistently
          "appid:^zen-beta$|^zen$|^firefox$,tags:1"
          "appid:^com\\.mitchellh\\.ghostty$|^ghostty$,tags:1"
          "appid:^figma-linux$|^Figma$,tags:1"
          "appid:^Obsidian$|^obsidian$,tags:1"

          # File manager & dialog-style helpers — float on the tag in view.
          "appid:^(${alternation thunarApps})$,isfloating:1,width:0.65,height:0.7"
          "appid:^(${alternation dialogApps})$,isfloating:1,width:0.6,height:0.6"

          # Named scratchpads — chat & music
          # No width/height → fall back to scratchpad_width_ratio / scratchpad_height_ratio (1.0 = full screen).
          # windowrule width/height are PIXELS, not ratios — setting them here would override the ratio.
          "isnamedscratchpad:1,appid:^[Dd]iscord$"
          "isnamedscratchpad:1,appid:^[Ss]lack$"
          "isnamedscratchpad:1,appid:^sone$"

          # Audio/Wine sizing
          "appid:^REAPER$|^reaper$,isfloating:0"
          "title:^iLok|PACE|License,isfloating:1,width:0.6,height:0.6"
          "title:^IK Product Manager|IK Multimedia,isfloating:1,width:0.6,height:0.6"

          # Picture-in-Picture floating
          "title:^Picture-in-Picture$,isfloating:1,width:345,height:200"

          # DaVinci convert helper terminal
          "appid:^davinci-convert$,isfloating:1,width:640,height:400"

          # Catch-all: full application windows land on tag 2. Negative
          # lookahead built from noSweepApps — a `tags:` rule always beats the
          # parent-tag fallback in mango, so exempted appids must be listed.
          "appid:^(?!(${alternation noSweepApps})$),tags:2"
        ];

        # === Layer rules ===
        layerrule = [
          "noanim:1,noblur:1,layer_name:^selection$"
          "animation_type_open:fade,layer_name:^rofi$"
        ];

        # === Animations ===
        animations = 1;
        animation_duration_open = 120;
        animation_duration_close = 150;
        animation_duration_move = 80;
        animation_duration_tag = 100;
        animation_type_open = "zoom";
        animation_type_close = "fade";
        # Aggressive ease-out — snap to target fast, settle quick.
        animation_curve_move = "0.05,0.9,0.1,1.0";
        animation_curve_tag = "0.1,0.9,0.2,1.0";

        # === Mouse binds ===
        mousebind = [
          "SUPER,btn_left,moveresize,curmove"
          "SUPER,btn_right,moveresize,curresize"
          "SUPER,btn_middle,togglemaximizescreen,0"
        ];

        # === Keybinds ===
        bind = [
          # --- App launchers ---
          "SUPER,Return,spawn_shell,mango-focus-or-run ghostty 1 ghostty"
          "SUPER+SHIFT,Return,spawn,${terminal}"
          "SUPER,B,spawn_shell,mango-focus-or-run zen-beta 1 zen-beta"
          "SUPER,E,spawn,${fileManager}"
          "SUPER,space,spawn,noctalia msg panel-toggle launcher"

          # Friction-free note capture: rofi one-liner -> today's daily note.
          "SUPER,C,spawn,notes-capture"
          "SUPER+SHIFT,C,spawn_shell,${calcLauncher}"
          "SUPER,Z,spawn_shell,${windowSwitcher}"
          "SUPER+SHIFT,E,spawn_shell,${emojiPicker}"
          "SUPER+SHIFT,P,spawn_shell,${powerMenu}"
          "SUPER,N,spawn,rofi-vpn"
          "SUPER+SHIFT,N,spawn,rofi-network-manager"
          "SUPER+SHIFT,B,spawn,rofi-bluetooth"
          "SUPER+SHIFT,A,spawn,rofi-pulse-select"
          "SUPER,y,spawn_shell,handy --toggle-transcription"

          # --- Window management ---
          "SUPER,Q,killclient"
          "SUPER,G,togglefloating"
          "SUPER,F,togglefullscreen"
          "SUPER,O,toggleoverview"
          "SUPER,Period,zoom"

          # --- Layout cycling (user request) ---
          "SUPER,T,switch_layout"

          # --- Vim focus (focus windows) ---
          "SUPER,H,focusdir,left"
          "SUPER,L,focusdir,right"
          "SUPER,J,focusdir,down"
          "SUPER,K,focusdir,up"

          # --- Vim move ---
          "SUPER+SHIFT,H,exchange_client,left"
          "SUPER+SHIFT,L,exchange_client,right"
          "SUPER+SHIFT,J,exchange_client,down"
          "SUPER+SHIFT,K,exchange_client,up"


          # --- Master-area sizing ---
          "SUPER,V,setmfact,-0.05"
          "SUPER+SHIFT,V,setmfact,+0.05"

          # --- Scroller width preset cycle ---
          "SUPER,W,switch_proportion_preset,next"
          "SUPER+SHIFT,W,switch_proportion_preset,prev"

          # --- Raycast-style focus-or-run (SUPER+1..5) ---
          # Pinned tags via windowrule; helper launches if missing, then jumps to tag
          # and cycles focusstack until appid matches.
          "SUPER,1,spawn_shell,mango-focus-or-run zen-beta 1 zen-beta"
          "SUPER,2,spawn_shell,mango-focus-or-run ghostty 1 ghostty"
          "SUPER,3,spawn_shell,mango-focus-or-run figma-linux 1 figma-linux"
          "SUPER,4,spawn_shell,mango-focus-or-run obsidian 1 obsidian"

          # --- Tags (main <-> stash) ---
          "SUPER,Tab,spawn,mango-tag-toggle"
          "SUPER+SHIFT,Tab,spawn,mango-tag-toggle --carry"

          # --- Named scratchpads (sone / Discord / Slack) ---
          "SUPER,M,toggle_named_scratchpad,sone,none,sone"
          "SUPER,D,toggle_named_scratchpad,discord,none,discord"
          "SUPER,S,toggle_named_scratchpad,slack,none,slack"

          # --- Standard scratchpad pool ---
          "SUPER,I,minimized"
          "ALT,Z,toggle_scratchpad"
          "SUPER+SHIFT,I,restore_minimized"

          # --- Keyboard layout cycle (was SUPER+SHIFT+SPACE on niri — moved) ---
          "SUPER+ALT,SPACE,switch_keyboard_layout"

          # --- Lock / session ---
          "SUPER,Escape,spawn_shell,${shell} msg session lock"
          "SUPER+SHIFT,Escape,spawn_shell,${shell} msg session lock-and-suspend"

          # --- Reload / quit ---
          "SUPER+SHIFT,R,reload_config"
          "SUPER+SHIFT,BackSpace,quit"

          # --- Screenshots ---
          "ALT+SHIFT,4,spawn_shell,grim -g \"$(slurp)\" - | wl-copy"
          "ALT+SHIFT,5,spawn_shell,grim - | wl-copy"

          # --- Media keys ---
          "NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%+"
          "NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%-"
          "NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_SINK@ toggle"
          "NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_SOURCE@ toggle"
          "NONE,XF86MonBrightnessUp,spawn,brightnessctl set +5%"
          "NONE,XF86MonBrightnessDown,spawn,brightnessctl set 5%-"
          "NONE,XF86AudioNext,spawn,playerctl next"
          "NONE,XF86AudioPause,spawn,playerctl play-pause"
          "NONE,XF86AudioPlay,spawn,playerctl play-pause"
          "NONE,XF86AudioPrev,spawn,playerctl previous"
        ];
      };
    };
  };
}
