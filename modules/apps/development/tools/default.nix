args@{
  config,
  pkgs,
  lib,
  isLinux,
  mkCategory,
  ...
}:

mkCategory {
  _file = toString ./.;
  name = "tools";
} args
