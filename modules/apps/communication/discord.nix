args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "discord";
  packages = { pkgs, ... }: [ pkgs.discord ];
  description = "Discord chat and voice communication";
} args
