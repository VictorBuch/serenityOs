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
in
{
  options = lib.setAttrByPath (optPath ++ [ "enable" ]) (
    lib.mkEnableOption "Noctalia shell - A modern Wayland shell for niri"
  );

  config = lib.mkIf cfg.enable (
    let
      # NOTE: the davinci-convert and mangowc-layout-switcher bar plugins used
      # to be injected here. They ship pre-5.0 QML "entryPoints" manifests that
      # noctalia 5 (C++) cannot load, so they are omitted from the v5 bar until
      # ported to the v5 "entries" plugin format.
    in
    {
      programs.noctalia = {
        enable = true;

        # Custom settings - translated from .config/noctalia/settings.json
        # Colors now come from the wallpaper (theme.source = "wallpaper");
        # stylix's noctalia target is disabled so noctalia owns the palette and
        # regenerates app templates live. See modules/apps/theming/stylix.nix.
        settings = {
          # === Bar (v5) — migrated from the old v4 bar.widgets schema ===
          # v5 references widgets by NAME in start/center/end; per-instance
          # settings live in [widget.<name>] (the `widget` attr below). Seeded
          # names (cpu/temp/ram/media/clock/output_volume/spacer/...) map to a
          # type + preset; bare type names (workspaces/network/tray/...) resolve
          # directly; custom instances set a `type`.
          #
          # NOT included: the mangowc-layout-switcher and davinci-convert
          # plugins. Both ship pre-5.0 QML "entryPoints" manifests, which the
          # noctalia 5 (C++) engine cannot load (it needs an "entries" array).
          # They must be ported to the v5 plugin format before they can return.
          bar.main = {
            position = "bottom";
            thickness = 30; # compact (was bar.density = "compact")
            widget_spacing = 6;
            padding = 10;
            background_opacity = 1.0;
            reserve_space = true;

            start = [
              "workspaces"
              "cpu" # sysmon stat=cpu_usage (seeded)
              "temp" # sysmon stat=cpu_temp (seeded)
              "ram" # sysmon stat=ram_used (seeded)
              "disk" # custom sysmon, see widget.disk below
              "media"
            ];
            center = [ "clock" ];
            end = [
              "network" # single widget covers WiFi + VPN (was VPN + WiFi)
              "bluetooth"
              "spacer_a"
              "volume"
              "notifications"
              "keyboard_layout"
              "tray"
              "spacer_b"
              "control-center"
            ];
          };

          # Per-instance widget settings (v5 [widget.<name>]). Only settings that
          # exist in noctalia 5 are set; several v4 options (SystemMonitor multi-
          # metric toggles, Tray blacklist/colorizeIcons, ControlCenter distro
          # logo, per-widget onhover) have no v5 TOML equivalent — they are now
          # managed in the Settings panel (state), not config.toml.
          widget = {
            workspaces = {
              hide_when_empty = true; # was hideUnoccupied
              max_label_chars = 10; # was characterCount = 10
            };

            # sysmon renders ONE stat per instance. cpu/temp/ram are seeded;
            # add a disk instance (was SystemMonitor showDiskUsage).
            disk = {
              type = "sysmon";
              stat = "disk_used_pct";
            };

            media = {
              max_length = 145; # was maxWidth = 145
              hide_album_art = false; # was showAlbumArt = true
              title_scroll = "on_hover"; # was scrollingMode = "hover"
            };

            clock = {
              format = "{:%H:%M · %d %b}"; # was "HH:mm : dd MMM"
              tooltip_format = "{:%A, %d %B %Y}";
            };

            network.vpn_status = "replace";
            keyboard_layout.display = "short";
            notifications.hide_when_no_unread = true; # was hideWhenZero = true

            spacer_a = {
              type = "spacer";
              length = 20;
            };
            spacer_b = {
              type = "spacer";
              length = 20;
            };
          };

          # Shell (v5) — was v4 appLauncher / ui / general.
          shell = {
            font_family = "DejaVu Sans"; # was ui.fontDefault
            clipboard_enabled = true; # was appLauncher.enableClipboardHistory
            launcher = {
              show_icons = true;
              sort_by_usage = true;
            };
          };

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
            wallpaper_scheme = "vibrant";
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
          dock.enabled = false;

          # Location — feeds weather AND the theme "auto" day/night schedule.
          # Coordinates are used directly (no network geocoding needed) so the
          # sunrise/sunset light<->dark switch works reliably. Brno, CZ.
          location = {
            auto_locate = false;
            address = "Brno";
            latitude = 49.1951;
            longitude = 16.6068;
            # To pin exact switch times instead of astronomical sunset/sunrise:
            # custom_schedule = true;
            # sunset = "20:30";
            # sunrise = "07:30";
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
              automation.enabled = false; # day/night handled by theme auto, not random cycling
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
    }
  );
}
