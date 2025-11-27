args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "kitty";
  packages = { pkgs, unstable-pkgs }: [ unstable-pkgs.kitty ];
  description = "Kitty terminal emulator";
} args
