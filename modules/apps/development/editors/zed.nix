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
  name = "zed";
  packages = { pkgs, ... }: [ pkgs.zed-editor ];
  description = "zed-editor";
} args
