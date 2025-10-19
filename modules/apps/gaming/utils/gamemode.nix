args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "gamemode";
  packages = pkgs: [ pkgs.gamemode ];
  description = "GameMode performance optimization";
} args
