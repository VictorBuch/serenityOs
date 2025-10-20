args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "zoom";
  packages = pkgs: [ pkgs.zoom-us ];
  description = "Zoom video conferencing";
} args
