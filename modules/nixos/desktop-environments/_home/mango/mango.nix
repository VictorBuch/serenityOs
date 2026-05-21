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
  shell = "noctalia-shell";
  applicationLauncher = "fuzzel";
  colors = config.lib.stylix.colors.withHashtag;

  # Strip leading '#' for mango color format (0xRRGGBBAA expected)
  hexNoHash = c: lib.removePrefix "#" c;
  mangoColor = c: "0x${hexNoHash c}ff";
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

      autostart_sh = ''
        ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
        ${shell} &
        ${browser} &
        ${terminal} &
        easyeffects --gapplication-service &
        wl-paste --watch cliphist store &
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
        smartgaps = 1;
        no_border_when_single = 1;

        border_radius = 8;
        focused_opacity = 1.0;
        unfocused_opacity = 0.9;

        # === Blur ===
        # blur = 1;
        # blur_layer = 1;
        # blur_optimized = 1;
        # blur_params_num_passes = 3;
        # blur_params_radius = 6;
        # blur_params_noise = 0.015;
        # blur_params_brightness = 0.95;
        # blur_params_contrast = 0.95;
        # blur_params_saturation = 1.1;

        bordercolor = mangoColor colors.base03;
        focuscolor = mangoColor colors.base04;
        urgentcolor = mangoColor colors.base08;
        scratchpadcolor = mangoColor colors.base0D;

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
        circle_layout = "tile,grid,monocle,center_tile";

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
          "name:^DP-1$,width:2560,height:1440,refresh:144,x:0,y:0,scale:1.0"
          "name:^Virtual-1$,width:2560,height:1600,refresh:60,x:0,y:0,scale:1.1"
        ];

        # === Tag rules: layouts per tag ===
        tagrule = [
          "id:1,layout_name:tile"
          "id:2,layout_name:tile"
          "id:3,layout_name:tile"
        ];

        # === Window rules ===
        windowrule = [
          # Browser / terminal default to tag 1
          "appid:^zen-beta$|^zen$|^firefox$,tags:1"
          "appid:^com\\.mitchellh\\.ghostty$|^ghostty$,tags:2"

          # Named scratchpads — chat & music
          "isnamedscratchpad:1,width:1.0,height:1.0,appid:^[Dd]iscord$"
          "isnamedscratchpad:1,width:1.0,height:1.0,appid:^[Ss]lack$"
          "isnamedscratchpad:1,width:1.0,height:1.0,appid:^tidal-hifi$"

          # Audio/Wine sizing
          "appid:^REAPER$|^reaper$,width:0.85"
          "title:^iLok|PACE|License,isfloating:1,width:0.6,height:0.6"
          "title:^IK Product Manager|IK Multimedia,isfloating:1,width:0.6,height:0.6"

          # Picture-in-Picture floating
          "title:^Picture-in-Picture$,isfloating:1,width:345,height:200"

          # DaVinci convert helper terminal
          "appid:^davinci-convert$,isfloating:1,width:640,height:400"

          # Steam scratchpad-ish: just float, low priority
          "appid:^steam$,tags:3"
        ];

        # === Layer rules ===
        layerrule = [
          "noanim:1,noblur:1,layer_name:^selection$"
          "animation_type_open:fade,layer_name:^fuzzel$"
          # "noanim:1,noblur:1,layer_name:^noctalia-wallpaper.*$"
          # "noblur:1,layer_name:^noctalia-bar.*$"
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
          "NONE,btn_middle,togglemaximizescreen,0"
        ];

        # === Keybinds ===
        bind = [
          # --- App launchers ---
          "SUPER,Return,spawn,${terminal}"
          "SUPER,B,spawn,${browser}"
          "SUPER,F,spawn,${fileManager}"
          "SUPER,SPACE,spawn,${applicationLauncher}"

          # --- Window management ---
          "SUPER,Q,killclient"
          "SUPER,G,togglefloating"
          "SUPER+SHIFT,F,togglefullscreen"
          "SUPER,Tab,toggleoverview"
          "SUPER,Period,zoom"

          # --- Layout cycling (user request) ---
          "SUPER+SHIFT,SPACE,switch_layout"

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

          # --- Tag (workspace) switching ---
          "SUPER,1,view,1"
          "SUPER,2,view,2"
          "SUPER,3,view,3"
          "SUPER+SHIFT,1,tag,1"
          "SUPER+SHIFT,2,tag,2"
          "SUPER+SHIFT,3,tag,3"

          # --- Named scratchpads (Tidal / Discord / Slack) ---
          "SUPER,T,toggle_named_scratchpad,tidal-hifi,none,tidal-hifi"
          "SUPER,D,toggle_named_scratchpad,discord,none,discord"
          "SUPER,S,toggle_named_scratchpad,Slack,none,slack"

          # --- Standard scratchpad pool ---
          "SUPER,I,minimized"
          "ALT,Z,toggle_scratchpad"
          "SUPER+SHIFT,I,restore_minimized"

          # --- Keyboard layout cycle (was SUPER+SHIFT+SPACE on niri — moved) ---
          "SUPER+ALT,SPACE,switch_keyboard_layout"

          # --- Lock / session ---
          "SUPER,Escape,spawn_shell,${shell} ipc call lockScreen lock"
          "SUPER+SHIFT,Escape,spawn_shell,${shell} ipc call sessionMenu lockAndSuspend"

          # --- Reload / quit ---
          "SUPER+SHIFT,R,reload_config"
          "SUPER+SHIFT,M,quit"

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
