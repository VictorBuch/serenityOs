args@{
  config,
  pkgs,
  lib,
  mkHomeModule,
  ...
}:

mkHomeModule {
  name = "noctalia";
  optionPath = "home.desktop-environments.noctalia";
  description = "Noctalia shell - A modern Wayland shell for niri";

  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.noctalia-shell = {
        enable = true;

        # Custom settings - translated from .config/noctalia/settings.json
        settings = {
          # App Launcher
          appLauncher = {
            backgroundOpacity = 0.75;
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
            backgroundOpacity = 0.2;
            density = "compact";

            widgets = {
              left = [
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
              ];

              center = [
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

              right = [
                {
                  id = "Tray";
                  blacklist = [ ];
                  colorizeIcons = false;
                  favorites = [ ];
                }
                {
                  id = "Spacer";
                  width = 20;
                }
                {
                  id = "NotificationHistory";
                  hideWhenZero = true;
                  showUnreadBadge = true;
                }
                {
                  id = "Volume";
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
                  id = "KeyboardLayout";
                  displayMode = "onhover";
                }
                {
                  id = "Spacer";
                  width = 20;
                }
                {
                  id = "Clock";
                  customFont = "";
                  formatHorizontal = "HH:mm";
                  formatVertical = "HH mm - dd MM";
                  useCustomFont = false;
                  usePrimaryColor = true;
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
          dock.enabled = false;

          # General UI tweaks
          general = {
            radiusRatio = 0.5;
            screenRadiusRatio = 0.12;
            shadowOffsetX = 3;
          };

          # Location
          location.name = "Brno";

          # Notifications
          notifications.backgroundOpacity = 0.9;

          # Templates
          templates.fuzzel = true;

          # Fonts
          ui = {
            fontDefault = "JetBrainsMono Nerd Font Propo";
            fontFixed = "JetBrainsMono Nerd Font Propo";
            panelsOverlayLayer = false;
          };

          # Wallpaper management
          wallpaper = {
            directory = "${config.home.homeDirectory}/serenityOs/home/wallpapers";
            overviewEnabled = false;
            randomEnabled = true;
            randomIntervalSec = 3600;
            recursiveSearch = true;
            transitionDuration = 2500;

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

        # Custom color scheme (Monochrome) - translated from .config/noctalia/colors.json
        colors = {
          mError = "#dddddd";
          mOnError = "#111111";
          mOnPrimary = "#111111";
          mOnSecondary = "#111111";
          mOnSurface = "#828282";
          mOnSurfaceVariant = "#5d5d5d";
          mOnTertiary = "#111111";
          mOutline = "#3c3c3c";
          mPrimary = "#aaaaaa";
          mSecondary = "#a7a7a7";
          mShadow = "#000000";
          mSurface = "#111111";
          mSurfaceVariant = "#191919";
          mTertiary = "#cccccc";
        };
      };

      # Fix missing app icons in Qt applications
      # Override Kvantum theme with GTK3 for better icon detection
      # This properly overrides catppuccin's Kvantum via systemd environment.d
      # qt.platformTheme.name = lib.mkForce "gtk3";

      # Configure GTK icon theme for better icon resolution
      # Helps Qt's gtk3 platform theme find fallback icons
      gtk.iconTheme = {
        name = "Papirus-Dark";
      };

      # Fallback icon theme environment variable
      home.sessionVariables = {
        QS_ICON_THEME = "Papirus-Dark";
      };

      # Install Qt SVG support packages
      # Without these, Qt silently skips SVG icons (most modern icons are SVG)
      home.packages = with pkgs; [
        libsForQt5.qt5.qtsvg
        kdePackages.qtsvg
      ];
    };
} args
