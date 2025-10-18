{ lib, ... }:

{
  imports = [
    ./niri.nix
    ../common/rofi.nix
    ./waybar
    ../common/dunst.nix
     ../common/wlogout
    ../common/hyprlock
  ];

  home.desktop-environments = {
    niri = {
      enable = lib.mkDefault true;
      waybar.enable = lib.mkDefault true;
    };
    common = {
      rofi.enable = lib.mkDefault true;
      dunst.enable = lib.mkDefault false;
      wlogout.enable = lib.mkDefault true;
      hyprlock.enable = lib.mkDefault true;
    };
  };
}
