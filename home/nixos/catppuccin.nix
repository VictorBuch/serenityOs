{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  options = {
    home.catppuccin.enable = lib.mkEnableOption "Enables catppuccin home manager theming";
  };

  config = lib.mkIf config.home.catppuccin.enable {
    catppuccin = {
      enable = true;
      flavor = "mocha";
      accent = "blue";

      # Enable catppuccin for specific applications
      # kitty.enable = true;
      # ghostty.enable = true;
      # rofi.enable = false; # Using custom theme
      # hyprland.enable = true;
      # kvantum = {
      #   enable = true;
      #   flavor = "mocha";
      #   accent = "blue";
      # };
    };

    fonts.fontconfig = {
      enable = true;
      antialiasing = true;
      hinting = "slight";
      subpixelRendering = "rgb";
    };

    gtk = {
      enable = true;
      font = {
        name = "DejaVu Sans";
        size = 11;
      };
      theme = {
        name = "catppuccin-mocha-blue-standard";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "blue" ];
          size = "standard";
          variant = "mocha";
        };
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "kvantum";
      style.name = "kvantum";
    };

    home = {
      pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.catppuccin-cursors.mochaDark;
        name = "catppuccin-mocha-dark-cursors";
        size = 16;
      };
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        dejavu_fonts
        (catppuccin-gtk.override {
          accents = [ "blue" ];
          size = "standard";
          variant = "mocha";
        })
      ];

      sessionVariables = {
        GTK_THEME = "catppuccin-mocha-blue-standard";
        XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
        XCURSOR_SIZE = "16";
      };
    };

    # Force dark mode preference for GTK and GNOME applications
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "catppuccin-mocha-blue-standard";
        icon-theme = "Papirus-Dark";
      };
    };
  };
}
