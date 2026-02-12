args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "easyeffects";
  packages = { pkgs, ... }: [ pkgs.easyeffects ];
  description = "EasyEffects audio effects";
} args
