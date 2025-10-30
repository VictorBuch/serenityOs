args@{ config, pkgs, lib, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "it-tools";
  description = "IT Tools - collection of handy online tools for developers";
  packages = pkgs: [ pkgs.it-tools ];  # Make package available for Caddy

  extraConfig = {};
} args
