args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "virtualbox";
  category = "emulation";
  linuxPackages = { pkgs, ... }: [ pkgs.virtualbox ];
  description = "VirtualBox virtualization (Linux only)";
} args
