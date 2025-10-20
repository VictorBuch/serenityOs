args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "firefox";
  packages = pkgs: [ pkgs.firefox ];
  description = "Mozilla Firefox web browser";
} args
