{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.emulation.virtualbox.enable = lib.mkEnableOption "Enables VirtualBox";
  };

  config = lib.mkIf config.apps.emulation.virtualbox.enable {

    environment.systemPackages = with pkgs; [
      virtualbox
    ];
  };
}
