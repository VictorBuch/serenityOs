args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "tmux";
  packages = pkgs: [ pkgs.unstable.tmux ];
  description = "Tmux terminal multiplexer";
} args
