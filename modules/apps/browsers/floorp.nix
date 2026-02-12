args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "floorp";
  packages = { pkgs, ... }: [ pkgs.floorp ];
  description = "Floorp web browser";
} args
