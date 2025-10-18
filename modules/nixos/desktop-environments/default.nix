{ pkgs, lib, ... }:
{

  imports = [
    ./gnome.nix
    ./hyprland.nix
    ./kde.nix
    ./niri.nix
  ];

  desktop-environments.gnome.enable = lib.mkDefault false;
  desktop-environments.hyprland.enable = lib.mkDefault false;
  desktop-environments.kde.enable = lib.mkDefault false;
  desktop-environments.niri.enable = lib.mkDefault false;
}
