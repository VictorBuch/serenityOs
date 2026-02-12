args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "audacity";
  packages = { pkgs, ... }: [ pkgs.audacity ];
  description = "Audacity audio editor";
} args
