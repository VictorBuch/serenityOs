args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "sone";
  category = "audio";
  packages = { pkgs, ... }: [ pkgs.sone ];
  description = "Tidal music streaming";
} args
