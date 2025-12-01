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
  name = "neovim";
  packages = pkgs: [ pkgs.unstable.neovim ];
  description = "Neovim text editor";
} args
