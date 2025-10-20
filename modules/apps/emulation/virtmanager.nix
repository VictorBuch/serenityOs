args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "virtmanager";
  linuxPackages = pkgs: [ ]; # virt-manager enabled via programs.virt-manager
  description = "Virtual Machine Manager (Linux only)";
  linuxExtraConfig = {
    programs.virt-manager.enable = true;
    users.groups.libvirtd.members = [ "${config.user.userName}" ];
    virtualisation.libvirtd.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
} args
