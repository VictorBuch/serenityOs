args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "ps4";
  category = "gaming";
  packages = { pkgs, ... }: [ pkgs.shadps4 ];
  description = "PS4 emulator";
} args
