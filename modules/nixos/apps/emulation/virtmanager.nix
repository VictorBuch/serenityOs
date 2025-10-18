{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.emulation.virtmanager.enable = lib.mkEnableOption "Enables virt-manager";
  };

  config = lib.mkIf config.apps.emulation.virtmanager.enable {

    programs.virt-manager.enable = true;
    users.groups.libvirtd.members = [ "${config.user.userName}" ];
    virtualisation.libvirtd.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;

  };
}
