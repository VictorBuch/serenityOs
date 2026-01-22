{ pkgs, lib, ... }:
{
  imports = [
    ./hyprland
    ./gnome.nix
    ./niri
  ];
}
