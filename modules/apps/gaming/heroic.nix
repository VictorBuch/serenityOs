args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "heroic";
  packages = { pkgs, ... }: [ pkgs.heroic ];
  description = "Heroic Games Launcher";
} args
