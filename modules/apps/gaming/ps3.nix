args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "ps3";
  packages = pkgs: [ pkgs.rpcs3 ];
  description = "RPCS3 PS3 emulator";
} args
