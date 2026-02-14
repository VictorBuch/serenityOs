{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  options = {
    home.stylix.enable = lib.mkEnableOption "Enables stylix home manager";
  };

  config = lib.mkIf config.home.stylix.enable {
    stylix = {
      enable = true;
      autoEnable = true;
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/ayu-dark.yaml";
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
      };
    };

  };
}
