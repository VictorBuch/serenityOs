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
  name = "signal";
  packages = { pkgs, ... }: [ pkgs.signal-desktop ];
  description = "Private and secure messaging app";
} args
