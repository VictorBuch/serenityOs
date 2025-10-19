args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "qemu";
  packages = pkgs: [
    pkgs.qemu
    pkgs.quickemu
    pkgs.quickgui
  ];
  description = "QEMU virtualization with quickemu and quickgui";
} args
