{ lib, ... }:

{
  imports = [
    ./niri.nix
    ./focus-or-run.nix
    ../common/dunst.nix
    ../common/wlogout
    ../common/hyprlock
    ../common/fuzzel.nix
    ../common/noctalia.nix
  ];

  home.desktop-environments = {
    niri = {
      enable = lib.mkDefault true;
      focus-or-run.enable = lib.mkDefault true;
    };
    noctalia = {
      enable = lib.mkDefault true;
    };
    common = {
      fuzzel.enable = lib.mkDefault true;
      dunst.enable = lib.mkDefault false;
      wlogout.enable = lib.mkDefault true;
      hyprlock.enable = lib.mkDefault true;
    };
  };
}
