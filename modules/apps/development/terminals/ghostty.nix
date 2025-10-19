args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "ghostty";
  packages = pkgs: [ pkgs.ghostty ];
  description = "Ghostty terminal emulator";
} args
