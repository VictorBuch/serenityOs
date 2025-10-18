{ lib, ... }:

{
  imports = [
    ./hyprland.nix
    ../common/rofi.nix
    ../common/wlogout
    ../common/hyprlock
    # ./waybar
    ../common/dunst.nix
  ];

  home.desktop-environments = {
    hyprland = {
      enable = lib.mkDefault true;
      # waybar.enable = lib.mkDefault true;
    };
    common = {
      rofi.enable = lib.mkDefault true;
      dunst.enable = lib.mkDefault false;
      wlogout.enable = lib.mkDefault true;
      hyprlock.enable = lib.mkDefault true;
    };
  };
}
