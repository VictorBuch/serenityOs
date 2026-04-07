args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "nextcloud";
  category = "productivity";
  packages =
    { pkgs, ... }:
    [
      pkgs.nextcloud33
      pkgs.nextcloud-client
    ];
  description = "Nextcloud client";
} args
