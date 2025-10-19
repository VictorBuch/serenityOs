args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, system ? pkgs.system, ... }:

mkApp {
  _file = toString ./.;
  name = "zen";
  packages = pkgs: [ inputs.zen-browser.packages."${system}".default ];
  description = "Zen browser";
} args
