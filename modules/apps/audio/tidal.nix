args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "tidal";
  packages = pkgs: [ pkgs.tidal-hifi ];
  description = "Tidal music streaming";
} args
