args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "wine";
  packages = pkgs: [
    pkgs.wineWowPackages.stable
    pkgs.wineWowPackages.waylandFull
    pkgs.winetricks
    pkgs.protontricks
  ];
  description = "Wine Windows compatibility layer";
} args
