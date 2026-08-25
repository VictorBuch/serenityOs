args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "virtmanager";
  platforms = [ "linux" ];
  category = "emulation";
  packages = { pkgs, ... }: [ ]; # virt-manager enabled via programs.virt-manager
  description = "Virtual Machine Manager (Linux only)";
  extraConfig = {
    programs.virt-manager.enable = true;
    users.groups.libvirtd.members = [ "${config.user.userName}" ];
    virtualisation.libvirtd.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
} args
