args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "system-tools";
  packages =
    { pkgs, ... }:
    [
      pkgs.gcc
      pkgs.btop
      pkgs.filezilla
      pkgs.chromium
      pkgs.bottles
      pkgs.lm_sensors
      pkgs.pciutils
      pkgs.gparted
      pkgs.sops
    ];
  description = "System utility tools";
} args
