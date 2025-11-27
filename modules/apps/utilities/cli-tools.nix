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
  name = "cli-tools";
  packages = pkgs: [
    pkgs.pam
  ];
  description = "Command-line development and management tools";
} args
