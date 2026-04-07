args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "discord";
  category = "communication";
  packages = { pkgs, ... }: [ pkgs.discord ];
  description = "Discord chat and voice communication";
} args
