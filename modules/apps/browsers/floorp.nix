args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "floorp";
  category = "browsers";
  packages = { pkgs, ... }: [ pkgs.floorp ];
  description = "Floorp web browser";
} args
