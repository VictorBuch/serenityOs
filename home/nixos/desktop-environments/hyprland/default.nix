{ lib, ... }:

{
  imports = [
    ./hyprland.nix
    ../common/wlogout
    ../common/hyprlock
    ../common/dunst.nix
  ];

  home.desktop-environments = {
    hyprland = {
      enable = lib.mkDefault true;
    };
    common = {
      dunst.enable = lib.mkDefault false;
      wlogout.enable = lib.mkDefault true;
      hyprlock.enable = lib.mkDefault true;
    };
  };
}
