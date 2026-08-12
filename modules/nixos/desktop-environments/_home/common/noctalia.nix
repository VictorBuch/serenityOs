{
  config,
  pkgs,
  lib,
  osConfig ? { },
  ...
}:
let
  optPath = [ "home" "desktop-environments" "noctalia" ];
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

  config = lib.mkIf cfg.enable (
    {
      programs.noctalia = {
        enable = true;

        settings = {
          bar.order = [ "main" ]; # one bar named "main"
          bar.main = {
            position = "bottom";
            thickness = 24;
            background_opacity = 0.1;
            shadow = false;

            start = [
              "clock"
              "spacer_2"
              "control-center"
              "wallpaper"
              "status" # pozzoo/hassio widget
              "nix-monitor" # avivbintangaringga/nix-monitor widget
            ]
            ++ lib.optional davinci.enable "davinci-convert"; # local plugin widget
            center = [ "workspaces" ];
              
            end = [
              "tray"
              "spacer_2"
              "notifications"
              "network"
              "bluetooth"
              "volume"
              "brightness"
              "spacer_2"
              "session"
            ];
          };

          plugins = {
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

          # Per-instance widget settings (v5 [widget.<name>]).
          widget = {
            clock.format = "{:%H:%M %d/%m}";
            control-center.glyph = "󱄅";
            media.hide_when_no_media = true;
            network.show_label = false;
            tray.hidden = [ "nm-applet" ];

            # Plugin widgets — reference the installed community plugins.
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

          # Shell (v5)
          shell = {
            font_family = "Maple Mono NF"; # was ui.fontDefault
            clipboard_enabled = true; # was appLauncher.enableClipboardHistory
            lang = "en";
            launcher = {
              show_icons = true;
              sort_by_usage = true;
            };
            panel = {
              transparency_mode = "glass";
              wallpaper_placement = "floating";
              wallpaper_position = "center";
            };
          };

          # Accessibility (ported from GUI state)
          accessibility.ui_scale = 1.05;

          # === Dynamic theming (Material You from wallpaper) ===
          # Colors are derived live from the active wallpaper. Noctalia
          # regenerates the palette (and all enabled app templates below)
          # whenever the wallpaper changes, and switches light<->dark on the
          # sunrise/sunset schedule from [location] because mode = "auto".
          # This replaces the old stylix-fed custom palette; stylix's noctalia
          # target is disabled in modules/apps/theming/stylix.nix so this wins.
          theme = {
            mode = "auto"; # dark | light | auto (auto = day/night via [location])
            source = "wallpaper"; # generate palette from the current wallpaper
            # Generator algorithm. Options: m3-tonal-spot | m3-content |
            # m3-fruit-salad | m3-rainbow | m3-monochrome | vibrant | faithful |
            # dysfunctional | muted. "vibrant" gives a rich, cohesive tinted
            # desktop (catppuccin/tokyo-night vibe); switch to m3-tonal-spot for
            # a softer, more neutral Material You look.
            wallpaper_scheme = "soft";
            # Keep this OFF. It runs applyPureBlackDark() over the generated
            # palette and re-anchors the whole dark surface ramp to #000000
            # (an OLED option), which throws away the wallpaper-derived surface
            # before any template renders. With cloudsnight.jpg + faithful that
            # is the difference between terminal_background #091034 (the deep
            # blue of the wallpaper) and a flat #000000 — verified with
            # `noctalia theme <img> --scheme faithful --dark [--pure-black]`.
            # It applies desktop-wide: bar, panels, ghostty, kitty, btop, gtk, qt.
            pure_black_dark = false;

            # Push the wallpaper-derived colors into real apps so every surface
            # matches the shell in real time. Each app also needs its stylix
            # color target disabled + a one-line include (see the app modules).
            templates = {
              enable_builtin_templates = true;
              # NOTE: starship is intentionally excluded — its template edits
              # the starship config in place, which fails on home-manager's
              # read-only symlink. All templates below use an include/theme file
              # that noctalia writes to a path HM does not manage.
              builtin_ids = [
                "mango" # window borders / decorations (live via mmsg reload)
                "ghostty" # primary terminal (live via SIGUSR2)
                "kitty" # terminal
                "btop" # system monitor (live via SIGUSR2)
                "gtk3" # GTK3 apps (thunar, dialogs, ...)
                "gtk4" # GTK4 apps
                "qt" # Qt apps (qt6ct)
              ];
              enable_community_templates = false;
            };
          };

          # Disable dock (v5)
          # Dock stays hidden, but keep the pin declarative for when it's on.
          dock = {
            enabled = false;
            pinned = [ ];
          };

          # Location — feeds weather AND the theme "auto" day/night schedule.
          # Coordinates are used directly (no network geocoding needed) so the
          # sunrise/sunset light<->dark switch works reliably. Prague, CZ.
          location = {
            auto_locate = false;
            address = "Prague, Czech";
            latitude = 50.0755;
            longitude = 14.4378;
            # To pin exact switch times instead of astronomical sunset/sunrise:
            custom_schedule = true;
            sunset = "20:30";
            sunrise = "07:30";
          };

          # Panel/notification/OSD opacity (previously from stylix opacity.popups)
          notification.background_opacity = 0.97;
          osd.background_opacity = 0.97;

          # === Wallpaper (v5) — dynamic day/night ===
          # With theme.mode = "auto", noctalia switches to a wallpaper from
          # directory_light during the day and directory_dark at night (on the
          # [location] sunrise/sunset schedule), then regenerates the palette
          # from whichever wallpaper is active. Keep exactly one image in each
          # directory for a deterministic day/night pair.
          wallpaper =
            let
              wallDir = "${config.home.homeDirectory}/serenityOs/home/wallpapers";
            in
            {
              enabled = true;
              fill_mode = "crop";
              transition = [ "fade" ];
              transition_duration = 900;
              transition_on_startup = true;
              directory = "${wallDir}/night"; # fallback directory
              directory_light = "${wallDir}/day";
              directory_dark = "${wallDir}/night";
              default.path = lib.mkForce "${wallDir}/night/cloudsnight.jpg";
              # Automation must be ON for the day/night *image* swap: noctalia
              # only re-picks the wallpaper from directory_light/directory_dark
              # inside its automation tick (Wallpaper::runAutomation). With
              # exactly one image per directory this does not "cycle" — it just
              # switches day<->night when the theme mode flips on the
              # sunrise/sunset schedule. interval_seconds is therefore the
              # granularity of that switch, not a rotation speed.
              #
              # TRAP: do NOT star these two wallpapers as "favorites" in the
              # wallpaper panel. A favorite records the theme mode + palette
              # scheme that were active when you starred it, and every
              # automation pick re-applies them (applyWallpaperSelection writes
              # theme.mode into ~/.local/state/noctalia/settings.toml, which
              # beats this file). Two favorites with different theme_mode values
              # make each tick flip the mode, which flips the light/dark
              # directory, which picks the other image — a self-sustaining
              # day<->night ping-pong every interval_seconds.
              automation = {
                enabled = true;
                interval_seconds = 1500;
                order = "alphabetical";
                recursive = false;
              };
            };
        };

      };

      # Adopt new HM default (was `config.gtk.theme` prior to 26.05)
      gtk.gtk4.theme = lib.mkForce null;

      # Quickshell icon hint — match stylix's WhiteSur
      home.sessionVariables = {
        QS_ICON_THEME = "WhiteSur-icon-theme-dark";
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
        icon_theme=WhiteSur-icon-theme-dark
        standard_dialogs=default
      '';
    }
  );
}
