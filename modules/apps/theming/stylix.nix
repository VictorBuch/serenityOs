args@{
  config,
  pkgs,
  lib,
  inputs,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "stylix";
  description = "Stylix home manager theming";
  # Inject stylix HM module and config via sharedModules
  linuxExtraConfig = {
    home-manager.sharedModules = [
      inputs.stylix.homeModules.stylix
      (
        { config, pkgs, ... }:
        {
          stylix = {
            enable = true;
            autoEnable = true;
            polarity = "dark";
            base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark.yaml";
            image = "${config.wallpaper}";

            cursor = {
              package = pkgs.whitesur-cursors;
              name = "WhiteSur-cursors";
              size = 16;
            };

            icons = {
              package = pkgs.whitesur-icon-theme;
              dark = "WhiteSur-icon-theme-dark";
            };

            fonts = {
              monospace = {
                package = pkgs.nerd-fonts.jetbrains-mono;
                name = "JetBrainsMono Nerd Font Mono";
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
            opacity.terminal = 0.85;

            # Disable targets that set nixpkgs.overlays in HM context
            # (conflicts with home-manager.useGlobalPkgs)
            targets = {
              nixos-icons.enable = false;
              gtksourceview.enable = false;
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
