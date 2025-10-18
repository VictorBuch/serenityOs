{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.emulation.qemu.enable = lib.mkEnableOption "Enables QEMU";
  };

  config = lib.mkIf config.apps.emulation.qemu.enable {

    environment.systemPackages = with pkgs; [
      qemu
      quickemu
      quickgui
    ];
  };
}
