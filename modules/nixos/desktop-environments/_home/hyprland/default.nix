{ lib, ... }:

{
  imports = [
    ./hyprland.nix
    ./focus-or-run.nix
    ../common/wlogout
    ../common/hyprlock
    ../common/fuzzel.nix
    ../common/noctalia.nix
  ];

  home.desktop-environments = {
    hyprland = {
      enable = lib.mkDefault true;
      focus-or-run.enable = lib.mkDefault true;
    };
    noctalia = {
      enable = lib.mkDefault true;
    };
    common = {
      fuzzel.enable = lib.mkDefault true;
      wlogout.enable = lib.mkDefault true;
      hyprlock.enable = lib.mkDefault true;
    };
  };
}
