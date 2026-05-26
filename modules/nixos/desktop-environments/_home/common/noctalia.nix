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
      # Check if DaVinci Resolve is enabled at the system level
      davinciEnabled = (osConfig.apps.media.davinci-resolve.enable or false);

      # MangoWC layout switcher plugin
      mangoLayoutPluginEnabled =
        (config.home.desktop-environments.common.mango-layout-plugin.enable or false);

      # Conditionally include the DaVinci Convert widget in the right bar section
      davinciWidget = lib.optional davinciEnabled {
        id = "plugin:davinci-convert";
      };

      mangoLayoutWidget = lib.optional mangoLayoutPluginEnabled {
        id = "plugin:mangowc-layout-switcher";
      };
    in
    {
      programs.noctalia-shell = {
        enable = true;

        # Custom settings - translated from .config/noctalia/settings.json
        # Stylix provides colors via programs.noctalia-shell.colors
        settings = {
          # App Launcher
          appLauncher = {
            # backgroundOpacity = 0.75; # managed by stylix
            enableClipboardHistory = true;
            terminalCommand = "ghostty -e";
          };

          # Audio
          audio = {
            cavaFrameRate = 60;
            visualizerType = "mirrored";
          };

          # Bar - heavily customized
          bar = {
            floating = false;
            position = "bottom";
            density = "compact";

            widgets = {
              left = mangoLayoutWidget ++ [
                {
                  id = "Workspace";
                  hideUnoccupied = true;
                  labelMode = "name";
                  characterCount = 10;
                }
                {
                  id = "SystemMonitor";
                  showCpuTemp = true;
                  showCpuUsage = true;
                  showDiskUsage = true;
                  showMemoryAsPercent = true;
                  showMemoryUsage = true;
                  showNetworkStats = false;
                }
                {
                  id = "MediaMini";
                  hideMode = "transparent";
                  hideWhenIdle = false;
                  maxWidth = 145;
                  scrollingMode = "hover";
                  showAlbumArt = true;
                  showVisualizer = true;
                  useFixedWidth = false;
                  visualizerType = "wave";
                }
              ];

              center = [
                {
                  id = "Clock";
                  customFont = "";
                  formatHorizontal = "HH:mm : dd MMM";
                  formatVertical = "HH mm - dd MM";
                  useCustomFont = false;
                  usePrimaryColor = true;
                }
              ];

              right = davinciWidget ++ [
                {
                  id = "VPN";
                  displayMode = "onhover";
                }
                {
                  id = "WiFi";
                  displayMode = "onhover";
                }
                {
                  id = "Bluetooth";
                  displayMode = "onhover";
                }
                {
                  id = "Spacer";
                  width = 20;
                }
                {
                  id = "Volume";
                  displayMode = "onhover";
                }
                {
                  id = "NotificationHistory";
                  hideWhenZero = true;
                  showUnreadBadge = true;
                }
                {
                  id = "KeyboardLayout";
                  displayMode = "onhover";
                }
                {
                  id = "Tray";
                  blacklist = [ "nm-applet" ];
                  colorizeIcons = false;
                }
                {
                  id = "Spacer";
                  width = 20;
                }
                {
                  id = "ControlCenter";
                  customIconPath = "";
                  icon = "";
                  useDistroLogo = true;
                }
              ];
            };
          };

          # Color scheme
          colorSchemes = {
            darkMode = true;
            predefinedScheme = "Monochrome";
            generateTemplatesForPredefined = true;
          };

          # Disable dock
          dock = {
            enabled = false;
            backgroundOpacity = 1.0;
          };

          # General UI tweaks
          general = {
            radiusRatio = 0.5;
            screenRadiusRatio = 0.12;
            shadowOffsetX = 3;
          };

          # Location
          location.name = "Brno";

          # Notifications + OSD opacity managed by stylix (opacity.popups)

          # Templates
          templates.fuzzel = true;

          # Fonts
          ui = {
            fontDefault = "DejaVu Sans";
            fontFixed = "JetBrainsMono Nerd Font Mono";
            panelsOverlayLayer = false;
          };

          # Wallpaper management
          wallpaper = {
            directory = "${config.home.homeDirectory}/serenityOs/home/wallpapers";
            overviewEnabled = false;
            randomEnabled = false;
            randomIntervalSec = 3600;
            recursiveSearch = true;
            transitionDuration = 500;

            monitors = [
              {
                name = "DP-1";
                directory = "${config.home.homeDirectory}/serenityOs/home/wallpapers";
                wallpaper = "${config.home.homeDirectory}/serenityOs/home/wallpapers/house-in-mountains.png";
              }
              {
                name = "Virtual-1";
                directory = "${config.home.homeDirectory}/serenityOs/home/wallpapers";
                wallpaper = "${config.home.homeDirectory}/serenityOs/home/wallpapers/house-in-mountains.png";
              }
            ];
          };
        };

        # Plugin states
        plugins.states = lib.mkMerge [
          (lib.mkIf davinciEnabled {
            davinci-convert.enabled = true;
          })
          (lib.mkIf mangoLayoutPluginEnabled {
            mangowc-layout-switcher.enabled = true;
          })
        ];

      };

      # Adopt new HM default (was `config.gtk.theme` prior to 26.05)
      gtk.gtk4.theme = null;

      # Quickshell icon hint — match stylix's WhiteSur
      home.sessionVariables = {
        QS_ICON_THEME = "WhiteSur-icon-theme-dark";
      };

      # Install Qt SVG support packages
      # Without these, Qt silently skips SVG icons (most modern icons are SVG)
      home.packages = with pkgs; [
        libsForQt5.qt5.qtsvg
        kdePackages.qtsvg
      ];
    }
  );
}
