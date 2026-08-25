args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "virtualbox";
  platforms = [ "linux" ];
  category = "emulation";
  packages = { pkgs, ... }: [ pkgs.virtualbox ];
  description = "VirtualBox virtualization (Linux only)";
} args
