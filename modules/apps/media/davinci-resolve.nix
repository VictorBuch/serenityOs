args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "davinci-resolve";
  packages = pkgs: [ pkgs.davinci-resolve ];
  description = "DaVinci Resolve video editor";
} args
