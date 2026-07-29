args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "handy";
  category = "utilities";
  packages = { pkgs, ... }: [
    pkgs.handy
    pkgs.wtype
  ];
  description = "Voice to text";
} args
