{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [ ./_session.nix ];

  options = {
    desktop.compositor.niri.enable = lib.mkEnableOption "Niri (scrollable-tiling wlroots compositor)";
  };

  config = lib.mkIf config.desktop.compositor.niri.enable {

    desktop.session = {
      enable = true;
      name = "niri";
      homeModules = [ ./_home/niri ];
    };

    programs.niri = {
      enable = true;
      package = pkgs.niri;
    };

    # Use xdg-desktop-portal-gtk; the nixpkgs niri module sets niri.default.
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = [ "gtk" ];
      };
    };

    environment.systemPackages =
      (with pkgs; [
        nautilus
        xwayland-satellite # X11 compatibility layer for niri
      ])
      ++ [
        # noctalia from flake input (uses its own pkgs)
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
  };
}
