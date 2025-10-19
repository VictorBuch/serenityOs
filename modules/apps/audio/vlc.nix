args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "vlc";
  packages = pkgs: [ pkgs.vlc ];
  description = "VLC media player";
} args
