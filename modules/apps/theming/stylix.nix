args@{
  config,
  pkgs,
  lib,
  inputs,
  mkModule,
  ...
}:

let
  # Single source for the pointer cursor. Consumed twice below: by stylix inside
  # home-manager, and by environment.sessionVariables at the system level.
  cursor = {
    package = pkgs.colloid-cursors;
    name = "Colloid-cursors";
    size = 16;
  };

  icons = {
    enable = true;
    package = pkgs.colloid-icon-theme;
    dark = "Colloid-Dark";
  };

  # The system-level table in modules/common/theme-authority.nix. Bound here
  # because `config` is shadowed inside the home-manager module below.
  authority = config.theme.authority;
in

mkModule {
  name = "stylix";
  platforms = [ "linux" ];
  category = "theming";
  description = "Stylix home manager theming";
  # Inject stylix HM module and config via sharedModules
  extraConfig = {
    # home.sessionVariables only reaches interactive shells (hm-session-vars.sh);
    # it never reaches a compositor launched by the display manager, which then
    # falls back to the default cursor theme. These have to be session-level.
    environment.sessionVariables = {
      XCURSOR_THEME = cursor.name;
      XCURSOR_SIZE = toString cursor.size;
    };

    home-manager.sharedModules = [
      inputs.stylix.homeModules.stylix
      (
        {
          config,
          pkgs,
          lib,
          osConfig ? { },
          ...
        }:
        {
          stylix = {
            enable = true;
            autoEnable = true;
            # HM uses useGlobalPkgs; disable overlays to avoid nixpkgs.overlays conflict
            overlays.enable = false;
            polarity = "dark";
            base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";
            image = "${config.wallpaper}";

            inherit cursor;

            inherit icons;

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

            # One entry per stylix target the authority table hands to someone
            # else. Adding an app to that table is what switches its target off.
            targets = (lib.genAttrs authority.stylix.disabledTargets (_: { enable = false; })) // {
              # Not an authority question: these two set nixpkgs.overlays in the
              # HM context, which conflicts with home-manager.useGlobalPkgs.
              nixos-icons.enable = false;
              gtksourceview.enable = false;

              zen-browser.profileNames = lib.mkIf (config.programs.zen-browser.enable or false) [
                config.home.username
              ];
            };
          };

          home.packages = [ icons.package ];

          dconf.settings."org/gnome/desktop/interface" = {
            icon-theme = icons.dark;
            cursor-theme = cursor.name;
            cursor-size = cursor.size;
          };
        }
      )
    ];
  };
} args
