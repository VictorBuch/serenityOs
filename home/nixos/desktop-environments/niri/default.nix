{ lib, ... }:

{
  imports = [
    ./niri.nix
    ./waybar
    ../common/dunst.nix
    ../common/wlogout
    ../common/hyprlock
    ../common/rofi.nix
    ../common/fuzzel.nix
    ../common/noctalia.nix
  ];

  home.desktop-environments = {
    niri = {
      enable = lib.mkDefault true;
      waybar.enable = lib.mkDefault true;
    };
    noctalia = {
      enable = lib.mkDefault true;
    };
    common = {
      rofi.enable = lib.mkDefault true;
      fuzzel.enable = lib.mkDefault true;
      dunst.enable = lib.mkDefault false;
      wlogout.enable = lib.mkDefault true;
      hyprlock.enable = lib.mkDefault true;
    };
  };
}
