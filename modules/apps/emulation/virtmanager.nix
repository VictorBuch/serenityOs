{
  flake.modules.nixos.virtmanager =
    { config, ... }:
    {
      programs.virt-manager.enable = true;
      users.groups.libvirtd.members = [ "${config.user.userName}" ];
      virtualisation.libvirtd.enable = true;
      virtualisation.spiceUSBRedirection.enable = true;
    };
}
