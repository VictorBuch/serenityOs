{ pkgs, lib, ... }:
{

  imports = [
    ./hyprland
    ./gnome/gnome.nix
    ./niri
  ];
}
