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
    desktop.compositor.hyprland.enable = lib.mkEnableOption "Hyprland (dynamic tiling Wayland compositor)";
  };

  config = lib.mkIf config.desktop.compositor.hyprland.enable {

    desktop.session = {
      enable = true;
      name = lib.mkDefault "hyprland";
      homeModules = [ ./_home/hyprland ];
    };

    programs.hyprland.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };

    services.dbus.packages = [ pkgs.kdePackages.kio-fuse ];

    environment.systemPackages =
      (with pkgs; [
        kdePackages.dolphin
        kdePackages.ark
        kdePackages.kio-extras
        kdePackages.kio-fuse
        kdePackages.ffmpegthumbs
        kdePackages.kdegraphics-thumbnailers

        brightnessctl
        playerctl
      ])
      ++ [
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
  };
}
