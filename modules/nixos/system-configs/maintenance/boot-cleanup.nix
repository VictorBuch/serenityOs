{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{

  options = {
    boot-cleanup.enable = lib.mkEnableOption "Enable automatic boot entry cleanup";
  };

  config = lib.mkIf config.boot-cleanup.enable {

    # Limit the number of boot generations to prevent /boot from filling up
    # Works for both systemd-boot and GRUB
    boot.loader.systemd-boot.configurationLimit = lib.mkDefault 5;
    boot.loader.grub.configurationLimit = lib.mkDefault 5;

    # Also limit the number of NixOS generations kept in the profile
    nix.gc.automatic = lib.mkDefault true;

  };
}
