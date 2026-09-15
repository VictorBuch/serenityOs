args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "ps2";
  category = "gaming";
  packages = { pkgs, ... }: [ pkgs.pcsx2 ];
  description = "RPSX2 ps2 emulator";
} args
