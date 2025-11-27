args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "ghostty";
  packages = { pkgs, unstable-pkgs }: [ unstable-pkgs.ghostty ];
  description = "Ghostty terminal emulator";
} args
