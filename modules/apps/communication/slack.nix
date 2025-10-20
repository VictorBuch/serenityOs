args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "slack";
  packages = pkgs: [ pkgs.slack ];
  description = "Slack team communication";
} args
