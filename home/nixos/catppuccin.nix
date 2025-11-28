{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # imports = [
  #   inputs.catppuccin.homeModules.catppuccin # Bug with anki in 25.05
  # ];

  options = {
    home.catppuccin.enable = lib.mkEnableOption "Enables catppuccin home manager theming";
  };

  config = lib.mkIf config.home.catppuccin.enable {
    # catppuccin = {
    #   enable = true;
    #   flavor = "mocha";
    #   accent = "mauve";

    #   # Enable catppuccin for specific applications
    #   kitty.enable = true;
    #   ghostty.enable = true;
    #   rofi.enable = false; # Using custom theme
    #   hyprland.enable = true;
    #   waybar.enable = false; # Using custom theme with catppuccin colors
    #   kvantum = {
    #     enable = true;
    #     flavor = "mocha";
    #     accent = "mauve";
    #   };
    # };

    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.catppuccin-cursors.mochaDark;
      name = "catppuccin-mocha-dark-cursors";
      size = 14;
    };

    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      dejavu_fonts
      (catppuccin-gtk.override {
        accents = [ "mauve" ];
        size = "standard";
        variant = "mocha";
      })
    ];

    gtk = {
      enable = true;
      font = {
        name = "DejaVu Sans";
        size = 11;
      };
      theme = {
        name = "catppuccin-mocha-mauve-standard";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "mauve" ];
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

    home.sessionVariables = {
      GTK_THEME = "catppuccin-mocha-mauve-standard";
      XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
      XCURSOR_SIZE = "14";
    };

    # Force dark mode preference for GTK and GNOME applications
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "catppuccin-mocha-mauve-standard";
        icon-theme = "Papirus-Dark";
      };
    };
  };
}
