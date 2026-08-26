args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "bottles";
  category = "emulation";
  packages = { pkgs, ... }: [
    pkgs.bottles
  ];
  description = "Windows emulation";
} args
