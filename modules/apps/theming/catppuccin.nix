{ inputs, mkModule, ... }:

mkModule {
  name = "catppuccin";
  category = "theming";
  description = "Catppuccin home manager theming";
  # Inject catppuccin HM module and config via sharedModules
  linuxExtraConfig = {
    home-manager.sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
      (
        { config, pkgs, lib, ... }:
        {
          catppuccin = {
            enable = true;
            flavor = "mocha";
            accent = "blue";
            cache.enable = true;
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
              size = 12;
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
            gtk4 = {
              theme = null;
              extraConfig = {
                gtk-application-prefer-dark-theme = true;
              };
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
        }
      )
    ];
  };
}
