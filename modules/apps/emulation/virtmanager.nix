{ config, mkModule, ... }:

mkModule {
  name = "virtmanager";
  category = "emulation";
  linuxPackages = { pkgs, ... }: [ ]; # virt-manager enabled via programs.virt-manager
  description = "Virtual Machine Manager (Linux only)";
  linuxExtraConfig = {
    programs.virt-manager.enable = true;
    users.groups.libvirtd.members = [ "${config.user.userName}" ];
    virtualisation.libvirtd.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
