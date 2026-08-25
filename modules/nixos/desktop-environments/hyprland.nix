{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./_session.nix ];

  options = {
    desktop.compositor.hyprland.enable = lib.mkEnableOption "Hyprland (wlroots compositor)";
  };

  config = lib.mkIf config.desktop.compositor.hyprland.enable {

    desktop.session = {
      enable = true;
      name = "hyprland";
      homeModule = ./_home/hyprland;
    };

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = lib.mkDefault "*";
        hyprland.default = [
          "hyprland"
          "gtk"
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      hypridle # Idle
      hyprlock # Lock screen
      # Bar provided by noctalia via home-manager (./_home/common/noctalia.nix)
      hyprpolkitagent
      dunst # Notification manager
      nautilus
      hyprshot # Screenshot tool
      wlogout
    ];
  };
}
