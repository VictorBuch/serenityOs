{
  config,
  pkgs,
  lib,
  osConfig ? { },
  ...
}:
let
  optPath = [
    "home"
    "desktop-environments"
    "noctalia"
  ];
  cfg = lib.attrByPath optPath { enable = false; } config;

  # The DaVinci Convert bar widget ships as a local noctalia plugin from
  # ../common/davinci-convert.nix. That module is only imported by the DEs
  # that want it, so everything below stays optional.
  davinci = lib.attrByPath [ "home" "desktop-environments" "common" "davinci-convert" ] {
    enable = false;
  } config;
in
{
  options = lib.setAttrByPath (optPath ++ [ "enable" ]) (
    lib.mkEnableOption "Noctalia shell - A modern Wayland shell for niri"
  );

  config = lib.mkIf cfg.enable ({
    programs.noctalia = {
      enable = true;

      settings = {
        bar.order = [ "main" ];
        bar.main = {
          position = "left";
          thickness = 40;
          background_opacity = 0.3;
          radius = 12;
          padding = 12;
          widget_spacing = 6;
          font_weight = 500;
          concave_edge_corners = true;
          hover_highlight = true;
          show_on_workspace_switch = true;

          # Solid pills on a glass strip: the capsules carry the contrast, the
          # bar itself stays transparent.
          capsule = false;
          capsule_fill = "surface_variant";
          capsule_opacity = 1.0;
          capsule_padding = 6;
          capsule_thickness = 0.76;

          shadow = false;
          contact_shadow = false;

          start = [
            "control-center"
            "wallpaper"
            "status" # pozzoo/hassio widget
            "nix-monitor" # avivbintangaringga/nix-monitor widget
          ]
          ++ lib.optional davinci.enable "davinci-convert" # local plugin widget
          ++ [
            "spacer_2"
            "clock"
          ];
          center = [ "workspaces" ];
          end = [
            "tray"
            "spacer_2"
            "notifications"
            "network"
            "bluetooth"
            "volume"
            "spacer_2"
            "session"
          ];
        };

        accessibility.ui_scale = 1.05;

        shell = {
          font_family = "Maple Mono NF";
          lang = "en";
          date_format = "%A, %x";
          time_format = "{:%H:%M}";
          clipboard_enabled = true;
          clipboard_history_max_entries = 100;
          settings_show_advanced = true;
          setup_wizard_enabled = false;

          # mango's autostart_sh runs polkit-gnome-authentication-agent-1, so
          # the shell must not also register one.
          polkit_agent = false;

          popup_shadows = false;
          screen_corners = {
            enabled = true;
            size = 12;
          };

          # The shell owns screenshots now (mango binds msg screenshot-region
          # and screenshot-fullscreen), so these stop being cosmetic. The old
          # grim | wl-copy binds only ever put the image on the clipboard.
          screenshot = {
            copy_to_clipboard = true;
            save_to_file = true;
            freeze_screen = true;
            show_cursor = false;
          };

          launcher = {
            show_icons = true;
            sort_by_usage = true;
            categories = true;
            fetch_exchange_rates = true;
            provider_prefix = "/";
          };

          panel = {
            transparency_mode = "glass";
            borders = false;
            shadow = false;
            floating_layer = "overlay";
            floating_offset = 8;
            launcher_placement = "floating";
            launcher_position = "center";
            clipboard_placement = "floating";
            clipboard_position = "center";
            wallpaper_placement = "floating";
            wallpaper_position = "center";
            control_center_placement = "attached";
            session_placement = "attached";
          };

          session = {
            show_shortcuts = true;
            actions = [
              {
                action = "lock";
                shortcut = "1";
                enabled = true;
              }
              {
                action = "logout";
                shortcut = "2";
                enabled = true;
              }
              {
                action = "lock_and_suspend";
                shortcut = "3";
                enabled = true;
              }
              {
                action = "reboot";
                shortcut = "4";
                enabled = true;
              }
              {
                action = "shutdown";
                shortcut = "5";
                enabled = true;
                variant = "destructive";
              }
            ];
          };
        };

        # === Dynamic theming (Material You from wallpaper) ===
        # Colors are derived live from the active wallpaper and pushed into
        # every app whose template is listed below. Stylix's colour targets for
        # those apps are disabled in modules/apps/theming/stylix.nix so this
        # wins; see docs/adr/0001-nix-declares-the-shell.md.
        theme = {
          mode = "dark";
          source = "wallpaper";
          # Generator algorithm. Options: m3-tonal-spot | m3-content |
          # m3-fruit-salad | m3-rainbow | m3-monochrome | vibrant | faithful |
          # dysfunctional | muted | soft. "soft" keeps successive palettes in a
          # narrow band, which matters now that the wallpaper rotates.
          wallpaper_scheme = "soft";
          # Keep this OFF. It runs applyPureBlackDark() over the generated
          # palette and re-anchors the whole dark surface ramp to #000000
          # (an OLED option), which throws away the wallpaper-derived surface
          # before any template renders. With cloudsnight.jpg + faithful that
          # is the difference between terminal_background #091034 (the deep
          # blue of the wallpaper) and a flat #000000 -- verified with
          # `noctalia theme <img> --scheme faithful --dark [--pure-black]`.
          pure_black_dark = false;

          templates = {
            enable_builtin_templates = true;
            # NOTE: starship is intentionally excluded -- its template edits
            # the starship config in place, which fails on home-manager's
            # read-only symlink. Every template below writes an include/theme
            # file at a path HM does not manage.
            builtin_ids = [
              "mango" # window borders / decorations (live via mmsg reload)
              "ghostty" # primary terminal (live via SIGUSR2)
              "kitty" # terminal
              "btop" # system monitor (live via SIGUSR2)
              "gtk3" # GTK3 apps
              "gtk4" # GTK4 apps
              "qt" # qt6ct/qt5ct palette
              "kcolorscheme" # merges into ~/.config/kdeglobals -- Dolphin reads this
            ];
            enable_community_templates = false;
          };
        };

        # === Wallpaper ===
        # One flat pool. theme.mode is pinned to "dark", so noctalia only ever
        # reads directory_dark (src/shell/wallpaper/wallpaper_paths.cpp) --
        # directory is set to the same path so a future mode change cannot
        # silently empty the pool.
        wallpaper =
          let
            wallDir = "${config.home.homeDirectory}/serenityOs/home/wallpapers";
          in
          {
            enabled = true;
            fill_mode = "crop";
            edge_smoothness = 0.3;
            transition = [ "fade" ];
            transition_duration = 900;
            transition_on_startup = true;
            directory = wallDir;
            directory_dark = wallDir;
            automation = {
              enabled = true;
              interval_seconds = 21600; # 6h -- the whole palette relights on each pick
              order = "random";
              recursive = false;
            };
          };

        # Feeds the weather widget. No longer drives a day/night schedule.
        location = {
          auto_locate = false;
          address = "Prague, Czech";
          latitude = 50.0755;
          longitude = 14.4378;
        };

        lockscreen = {
          enabled = true;
          lock_before_suspend = true;
          blur_intensity = 0.5;
          tint_intensity = 0.3;
        };

        # noctalia authenticates against PAM service "login"
        # (src/auth/pam_authenticator.h), where u2fAuth is deliberately off in
        # modules/nixos/system/security.nix -- so unlock is password-only.
        idle = {
          behavior_order = [
            "lock"
            "screen-off"
            "lock-and-suspend"
          ];
          behavior.lock = {
            action = "lock";
            enabled = true;
            timeout = 600.0;
          };
          behavior."screen-off" = {
            action = "screen_off";
            enabled = true;
            timeout = 660.0;
          };
          behavior."lock-and-suspend" = {
            action = "lock_and_suspend";
            enabled = false;
            timeout = 900.0;
          };
        };

        notification = {
          background_opacity = 0.97;
          border = true;
          position = "top_right";
          offset_x = 20;
          offset_y = 8;
          collapse_on_dismiss = true;
          show_actions = true;
          show_app_name = true;
        };

        osd = {
          enabled = true;
          background_opacity = 0.97;
          border = true;
          position = "top_center";
          orientation = "horizontal";
          offset_x = 20;
          offset_y = 8;
          # brightness is absent on purpose: this is a desktop on external
          # panels with no backlight device, and enable_ddcutil is off.
          kinds = {
            bluetooth = true;
            caffeine = true;
            dnd = true;
            keyboard_backlight = true;
            keyboard_layout = true;
            lock_keys = true;
            media = true;
            nightlight = true;
            power_profile = true;
            privacy = true;
            volume = true;
            volume_input = true;
            volume_output = true;
            wifi = true;
          };
        };

        control_center = {
          width = 700;
          sidebar = "compact";
          show_session_button = true;
          show_shortcut_labels = true;
          shortcuts = [
            { type = "wifi"; }
            { type = "bluetooth"; }
            { type = "caffeine"; }
            { type = "nightlight"; }
            { type = "notification"; }
            { type = "power_profile"; }
          ];
        };

        # Plugin distribution. Declaring [[plugins.source]] at all replaces
        # noctalia's built-in defaults wholesale, so the two upstream git
        # sources are repeated here alongside the local one.
        plugins = {
          auto_update = true;
          source = [
            {
              name = "official";
              kind = "git";
              location = "https://github.com/noctalia-dev/official-plugins";
              enabled = true;
            }
            {
              name = "community";
              kind = "git";
              location = "https://github.com/noctalia-dev/community-plugins";
              enabled = true;
            }
          ]
          ++ lib.optional davinci.enable {
            name = "serenityos";
            kind = "path";
            location = "${davinci.pluginPackage}";
            enabled = true;
          };

          enabled = [
            "avivbintangaringga/nix-monitor"
          ]
          ++ lib.optional davinci.enable davinci.pluginId;
        };

        plugin_settings = {
          "avivbintangaringga/nix-monitor" = {
            update_command = "nfu";
            clean_command = "nh clean all -k 2 --optimise";
            hide_optimize_button = true;
          };
          "pozzoo/hassio".ha_url = "http://192.168.0.243:8124";
        };

        # Per-instance widget settings.
        widget = {
          # The bar is vertical, and an explicit vertical_format would be used
          # verbatim on one line (src/shell/bar/widgets/clock_widget.cpp:41).
          # Leaving it unset makes the fallback stack `format` on space/colon,
          # giving hour / minute / date on three lines.
          clock.format = "{:%H:%M %d/%m}";
          control-center.glyph = "󱄅";
          media.hide_when_no_media = true;
          network.show_label = false;
          tray.hidden = [ "nm-applet" ];

          nix-monitor = {
            type = "avivbintangaringga/nix-monitor:nix-monitor";
            show_text = false;
          };
          status.type = "pozzoo/hassio:status";
          spacer_2.type = "spacer";
        }
        // lib.optionalAttrs davinci.enable {
          davinci-convert.type = davinci.widgetType;
        };
      };

    };

    # Adopt new HM default (was `config.gtk.theme` prior to 26.05)
    gtk.gtk4.theme = lib.mkForce null;

    # Quickshell icon hint — match stylix
    home.sessionVariables = {
      QS_ICON_THEME = config.stylix.icons.dark;
    };

    # Install Qt SVG support packages
    # Without these, Qt silently skips SVG icons (most modern icons are SVG)
    home.packages = with pkgs; [
      qt5.qtsvg
      kdePackages.qtsvg

      # Backends for noctalia's live GTK/Qt templates (stylix targets for
      # these are disabled). noctalia sets adw-gtk3 / adw-gtk3-dark via
      # gsettings for day/night, and writes the qt6ct/qt5ct color scheme.
      adw-gtk3
      kdePackages.qt6ct
      libsForQt5.qt5ct
    ];

    # qt6ct base config: a static pointer to the color scheme noctalia's `qt`
    # template writes at runtime (~/.config/qt6ct/colors/noctalia.conf). HM
    # owns this file; noctalia only writes the separate colors file, so there
    # is no read-only conflict. This is what makes Qt apps pick up the palette.
    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.conf
      custom_palette=true
      style=Fusion
      icon_theme=${config.stylix.icons.dark}
      standard_dialogs=default
    '';
  });
}
