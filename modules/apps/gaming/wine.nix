args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "wine";
  # Use pkgs-stable for Wine gaming to avoid breaking changes
  packages =
    { pkgs, pkgs-stable, ... }:
    [
      pkgs-stable.wineWowPackages.stable
      pkgs-stable.wineWowPackages.waylandFull
      pkgs-stable.winetricks
      pkgs.protontricks # protontricks can stay on unstable
    ];
  description = "Wine Windows compatibility layer";
} args
