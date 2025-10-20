args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "virtualbox";
  linuxPackages = pkgs: [ pkgs.virtualbox ];
  description = "VirtualBox virtualization (Linux only)";
} args
