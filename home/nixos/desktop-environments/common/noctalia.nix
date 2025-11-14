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
      };

      # Fix missing app icons in Qt applications
      # Override Kvantum theme with GTK3 for better icon detection
      # This properly overrides catppuccin's Kvantum via systemd environment.d
      qt.platformTheme.name = lib.mkForce "gtk3";

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
