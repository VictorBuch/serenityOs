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
  name = "editors";
} args
