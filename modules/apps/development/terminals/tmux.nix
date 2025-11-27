args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "tmux";
  packages = { pkgs, unstable-pkgs }: [ unstable-pkgs.tmux ];
  description = "Tmux terminal multiplexer";
} args
