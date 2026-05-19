args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "system-tools";
  category = "utilities";
  packages =
    { pkgs, ... }:
    [
      pkgs.gcc
      pkgs.btop
      pkgs.filezilla
      pkgs.chromium
      # pkgs.bottles  # disabled: pulls i686 openldap which fails test017-syncreplication-refresh (nixpkgs#516392)
      pkgs.lm_sensors
      pkgs.pciutils
      pkgs.gparted
      pkgs.sops
      pkgs.jq
    ];
  description = "System utility tools";
} args
