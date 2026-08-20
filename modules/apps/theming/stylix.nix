args@{ config, pkgs, lib, inputs, mkModule, ... }:

mkModule {
  name = "stylix";
  category = "theming";
  description = "Stylix home manager theming";
  # Inject stylix HM module and config via sharedModules
  linuxExtraConfig = {
    home-manager.sharedModules = [
      inputs.stylix.homeModules.stylix
      (
        { config, pkgs, lib, osConfig ? { }, ... }:
        {
          stylix = {
            enable = true;
            autoEnable = true;
            # HM uses useGlobalPkgs; disable overlays to avoid nixpkgs.overlays conflict
            overlays.enable = false;
            polarity = "dark";
            base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";
            image = "${config.wallpaper}";

            cursor = {
              package = pkgs.colloid-cursors;
              name = "Colloid-dark-cursors";
              size = 16;
            };

            icons = {
              package = pkgs.colloid-icon-theme;
              dark = "Colloid-Dark";
            };

            fonts = {
              monospace = {
                package = osConfig.fonts.mono.package;
                name = osConfig.fonts.mono.familyMono;
              };
              sansSerif = {
                package = pkgs.dejavu_fonts;
                name = "DejaVu Sans";
              };
              serif = {
                package = pkgs.dejavu_fonts;
                name = "DejaVu Serif";
              };
            };
            opacity = {
              terminal = 0.85;
            };

            # Disable targets that set nixpkgs.overlays in HM context
            # (conflicts with home-manager.useGlobalPkgs)
            targets = {
              # qt.enable = true;
              # kde.enable = true;
              nixos-icons.enable = false;
              gtksourceview.enable = false;

              # === Cede color authority to noctalia ===
              # noctalia derives colors from the wallpaper (Material You) and
              # regenerates these apps' configs live. Stylix must NOT also write
              # their colors at build time, or the two fight (read-only symlinks
              # vs runtime writes, and mismatched palettes). Stylix still owns
              # fonts, cursor, icons, zen-browser, and the base16 fallback.
              noctalia.enable = false; # stop stylix feeding noctalia a custom palette
              "noctalia-shell".enable = false;
              ghostty.enable = false;
              kitty.enable = false;
              btop.enable = false;
              starship.enable = false;
              gtk.enable = false; # noctalia's gtk template owns gtk3/gtk4 colors
              qt.enable = false; # noctalia's qt template owns qt6ct/qt5ct colors

              # Zen browser stylix integration
              zen-browser.profileNames =
                lib.mkIf (config.programs.zen-browser.enable or false) [ config.home.username ];
            };
          };
        }
      )
    ];
  };
} args
