args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "handbrake";
  packages = pkgs: [ pkgs.handbrake ];
  description = "HandBrake video transcoder";
} args
