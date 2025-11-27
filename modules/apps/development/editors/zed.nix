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
  packages = { pkgs, unstable-pkgs }: [ unstable-pkgs.zed-editor ];
  description = "zed-editor";
} args
