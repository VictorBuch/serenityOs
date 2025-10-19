args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "kitty";
  packages = pkgs: [ pkgs.kitty ];
  description = "Kitty terminal emulator";
} args
