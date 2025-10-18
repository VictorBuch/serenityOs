{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./qemu.nix
  ];

  options = {
    apps.emulation.enable = lib.mkEnableOption "Enables all cross-platform emulation tools";
  };

  config = lib.mkIf config.apps.emulation.enable {
    apps.emulation.qemu.enable = lib.mkDefault true;
  };
}
